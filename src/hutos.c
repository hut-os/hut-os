#define _DEFAULT_SOURCE
#include <ctype.h>
#include <dirent.h>
#include <errno.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/reboot.h>
#include <sys/statvfs.h>
#include <sys/sysinfo.h>
#include <sys/utsname.h>
#include <unistd.h>

static int color;
static const char *cyan, *blue, *green, *amber, *red, *muted, *reset;
static int input_error;
static int require_positive(double x, const char *name);
static int mounted(const char *path);
static void interactive_mech(void);
static void interactive_chem(void);
static int system_action(const char *action);
static void system_menu(void);

static void colors_init(void) {
    color = isatty(STDOUT_FILENO) && getenv("NO_COLOR") == NULL &&
            (!getenv("TERM") || strcmp(getenv("TERM"), "dumb") != 0);
    cyan = color ? "\033[38;5;81m" : "";
    blue = color ? "\033[38;5;110m" : "";
    green = color ? "\033[38;5;114m" : "";
    amber = color ? "\033[38;5;179m" : "";
    red = color ? "\033[38;5;167m" : "";
    muted = color ? "\033[38;5;245m" : "";
    reset = color ? "\033[0m" : "";
}

static int term_width(void) {
    struct winsize ws;
    if (isatty(STDOUT_FILENO) && ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0 && ws.ws_col >= 40)
        return ws.ws_col > 88 ? 88 : ws.ws_col;
    return 72;
}

static void rule(const char *ch) {
    int n = term_width() - 4;
    if (n > 76) n = 76;
    printf("  ");
    for (int i = 0; i < n; i++) fputs(ch, stdout);
    putchar('\n');
}

static void title(const char *label) {
    putchar('\n');
    rule("─");
    printf("  %s%s%s\n", cyan, label, reset);
    rule("─");
}

static void row(const char *key, const char *value) {
    printf("  %s%-18s%s %s\n", blue, key, reset, value);
}

static double ask_number(const char *prompt) {
    char line[128], *end;
    for (;;) {
        printf("  %s: ", prompt);
        fflush(stdout);
        if (!fgets(line, sizeof line, stdin)) return NAN;
        errno=0;
        double x=strtod(line,&end);
        while (isspace((unsigned char)*end)) end++;
        if (!errno && end!=line && *end=='\0' && isfinite(x)) return x;
        printf("  %sPlease enter a finite number.%s\n",amber,reset);
    }
}

static int ask_positive(const char *prompt, double *out) {
    *out=ask_number(prompt);
    if (!isfinite(*out)) return 0;
    return require_positive(*out,prompt);
}

static void help(void) {
    puts("HUTOS  |  Engineering command environment");
    puts("");
    puts("SYSTEM");
    puts("  hutos about             System dashboard");
    puts("  hutos info              Detailed runtime information");
    puts("  hutos doctor            System health checks");
    puts("  hutos restart           Restart the computer (root required)");
    puts("  hutos poweroff          Power off the computer (root required)");
    puts("  hutos halt              Halt the computer (root required)");
    puts("  hutos version           HUTOS release and kernel");
    puts("  hutos update            Refresh configured package indexes");
    puts("  hutos tools             Interactive engineering toolkit");
    puts("");
    puts("MECHANICAL ENGINEERING");
    puts("  hutos mech beam L P E I [center|cantilever]");
    puts("                          Point-load beam: L m, P N, E Pa, I m^4");
    puts("  hutos mech stress F A dL L [yield_Pa]");
    puts("                          Normal stress, strain, modulus and safety factor");
    puts("  hutos mech thermo n T V  Ideal-gas pressure (mol, K, m^3)");
    puts("  hutos mech fluids rho v D mu  Reynolds number (SI units)");
    puts("  hutos mech units value unit  Convert common values to SI");
    puts("");
    puts("CHEMISTRY");
    puts("  hutos chem molarity moles liters");
    puts("  hutos chem dilution C1 V1 C2  Solve V2 in matching units");
    puts("  hutos chem gas n T V      Ideal-gas pressure (mol, K, m^3)");
    puts("  hutos chem molar-mass FORMULA  Formula groups support parentheses");
    puts("");
    puts("Append --help to a topic for examples. Use --plain for monochrome output.");
}

static double number(const char *s, const char *name) {
    char *end = NULL;
    errno = 0;
    double x = strtod(s, &end);
    if (errno || end == s || *end || !isfinite(x)) {
        fprintf(stderr, "%sInput error:%s %s must be a finite number.\n", red, reset, name);
        exit(2);
    }
    return x;
}

static double argnum(int argc, char **argv, int i, const char *name) {
    if (i >= argc) {
        fprintf(stderr, "Usage error: missing %s. Run 'hutos help'.\n", name);
        exit(2);
    }
    return number(argv[i], name);
}

static int require_positive(double x, const char *name) {
    if (!(x > 0.0)) {
        fprintf(stderr, "%sInput error:%s %s must be greater than zero.\n", red, reset, name);
        input_error = 1;
        return 0;
    }
    return 1;
}

static int require_nonnegative(double x, const char *name) {
    if (x < 0.0) {
        fprintf(stderr, "%sInput error:%s %s cannot be negative.\n", red, reset, name);
        input_error = 1;
        return 0;
    }
    return 1;
}

static void format_bytes(unsigned long long bytes, char *out, size_t cap) {
    const char *units[] = {"B", "KiB", "MiB", "GiB", "TiB"};
    double value = (double)bytes;
    int u = 0;
    while (value >= 1024.0 && u < 4) { value /= 1024.0; u++; }
    snprintf(out, cap, "%.1f %s", value, units[u]);
}

static void cpu_name(char *out, size_t cap) {
    FILE *f = fopen("/proc/cpuinfo", "r");
    char line[512];
    snprintf(out, cap, "unknown");
    if (!f) return;
    while (fgets(line, sizeof line, f)) {
        if (strncmp(line, "model name", 10) == 0 || strncmp(line, "Hardware", 8) == 0) {
            char *p = strchr(line, ':');
            if (p) {
                p++;
                while (isspace((unsigned char)*p)) p++;
                p[strcspn(p, "\r\n")] = 0;
                snprintf(out, cap, "%s", p);
                break;
            }
        }
    }
    fclose(f);
}

static void network_status(char *out, size_t cap) {
    DIR *dir=opendir("/sys/class/net");
    struct dirent *entry;
    int seen=0;
    snprintf(out,cap,"offline");
    if (!dir) return;
    while ((entry=readdir(dir)) != NULL) {
        if (entry->d_name[0]=='.' || strcmp(entry->d_name,"lo")==0) continue;
        seen=1;
        char path[512], state[32]="unknown";
        snprintf(path,sizeof path,"/sys/class/net/%s/operstate",entry->d_name);
        FILE *f=fopen(path,"r");
        if (f) { if (fgets(state,sizeof state,f)) state[strcspn(state,"\r\n")]=0; fclose(f); }
        snprintf(out,cap,"%.15s (%.10s)",entry->d_name,state);
        if (!strcmp(state,"up")) break;
    }
    closedir(dir);
    if (!seen) snprintf(out,cap,"no interface");
}

static unsigned package_count(void) {
    FILE *f = fopen("/var/lib/dpkg/status", "r");
    char line[512];
    unsigned count = 0;
    if (!f) return 0;
    while (fgets(line, sizeof line, f))
        if (strncmp(line, "Status: install ok installed", 28) == 0) count++;
    fclose(f);
    return count;
}

static void about(int detailed) {
    struct utsname u;
    struct sysinfo si;
    struct statvfs fs;
    char host[128] = "unknown", cpu[256], mem[64], avail[64], disk[64], uptime[96], net[64];
    char shell[128] = "unknown";
    gethostname(host, sizeof host - 1);
    cpu_name(cpu, sizeof cpu);
    memset(&si, 0, sizeof si);
    sysinfo(&si);
    format_bytes((unsigned long long)si.totalram * si.mem_unit, mem, sizeof mem);
    format_bytes((unsigned long long)si.freeram * si.mem_unit, avail, sizeof avail);
    if (statvfs("/", &fs) == 0) {
        unsigned long long used = (unsigned long long)(fs.f_blocks - fs.f_bfree) * fs.f_frsize;
        format_bytes(used, disk, sizeof disk);
    } else snprintf(disk, sizeof disk, "unavailable");
    unsigned long days = si.uptime / 86400, hours = (si.uptime / 3600) % 24, mins = (si.uptime / 60) % 60;
    snprintf(uptime, sizeof uptime, "%lu d  %lu h  %lu min", days, hours, mins);
    const char *sh = getenv("SHELL");
    if (sh && *sh) snprintf(shell, sizeof shell, "%s", sh);
    uname(&u);

    printf("\n  %s┌────────────────────────────────────────────────────┐%s\n", cyan, reset);
    printf("  %s│  H U T O S   ·   ENGINEERING LINUX                 │%s\n", cyan, reset);
    printf("  %s│  Hamedan University of Technology                  │%s\n", cyan, reset);
    printf("  %s└────────────────────────────────────────────────────┘%s\n", cyan, reset);
    title(detailed ? "SYSTEM INFORMATION" : "SYSTEM STATUS");
    row("Operating system", "HUTOS 3.1.0");
    row("Kernel", u.release);
    row("Architecture", u.machine);
    row("Hostname", host);
    row("CPU", cpu);
    row("Memory", mem);
    row("Available", avail);
    row("Uptime", uptime);
    row("Root usage", disk);
    row("Shell", shell);
    char pkg[32]; snprintf(pkg, sizeof pkg, "%u registered", package_count());
    row("Packages", pkg);
    row("Package tools", "apt-compatible / dpkg");
    network_status(net,sizeof net);
    row("Network", net);
    title(detailed ? "SYSTEM COMPONENTS" : "ENGINEERING ENVIRONMENT");
    if (detailed) {
        FILE *f=fopen("/proc/1/comm","r"); char initname[64]="unknown";
        if (f) { if (fgets(initname,sizeof initname,f)) initname[strcspn(initname,"\r\n")]=0; fclose(f); }
        row("Init",initname);
        row("Userspace","BusyBox + Zsh");
        row("Root mount",mounted("/") ? "mounted" : "unavailable");
    }
    row("Mechanical", "Beam, stress, thermo, fluids, units");
    row("Chemistry", "Molar mass, molarity, dilution, ideal gas");
    row("Access tools", "hutos tools  ·  hutos help");
    row("Power controls", "hutos restart  ·  hutos poweroff");
    printf("\n  %sHamedan University of Technology · HUTOS project%s\n\n", muted, reset);
}

static int mounted(const char *path) {
    FILE *f = fopen("/proc/mounts", "r");
    char dev[256], mountpoint[256], type[64], opts[256];
    int found = 0;
    if (!f) return 0;
    while (fscanf(f, "%255s %255s %63s %255s %*d %*d", dev, mountpoint, type, opts) == 4)
        if (strcmp(mountpoint, path) == 0) { found = 1; break; }
    fclose(f);
    return found;
}

static void checkline(const char *name, int good, const char *hint) {
    printf("  %s%-7s%s %-25s", good ? green : amber, good ? "READY" : "CHECK", reset, name);
    if (!good && hint) printf(" %s%s%s", muted, hint, reset);
    putchar('\n');
}

static int doctor(void) {
    struct sysinfo si;
    char cpu[256]; cpu_name(cpu, sizeof cpu);
    sysinfo(&si);
    title("HUTOS SYSTEM HEALTH");
    checkline("Kernel", access("/proc/version", R_OK) == 0, "check that /proc is mounted");
    checkline("Memory", si.totalram > 0, "system memory data unavailable");
    checkline("Root filesystem", statvfs("/", &(struct statvfs){0}) == 0, "root filesystem is inaccessible");
    checkline("/proc", mounted("/proc"), "mount -t proc proc /proc");
    checkline("/sys", mounted("/sys"), "mount -t sysfs sysfs /sys");
    checkline("/dev/pts", mounted("/dev/pts"), "mount -t devpts devpts /dev/pts");
    checkline("Package database", access("/var/lib/dpkg/status", R_OK) == 0, "package list is not initialized");
    checkline("CPU", strcmp(cpu, "unknown") != 0, "CPU model is not exposed by this platform");
    checkline("Network interface", access("/sys/class/net/lo", F_OK) == 0, "network sysfs is unavailable");
    checkline("Login supervisor", access("/sbin/getty", X_OK) == 0, "BusyBox getty is missing");
    checkline("Restart command", access("/sbin/reboot", X_OK) == 0, "BusyBox reboot applet is missing");
    checkline("Poweroff command", access("/sbin/poweroff", X_OK) == 0, "BusyBox poweroff applet is missing");
    puts("");
    return 0;
}

static int system_action(const char *action) {
    const char *path = NULL;
    const char *applet = NULL;
    if (!strcmp(action, "restart") || !strcmp(action, "reboot")) { path = "/sbin/reboot"; applet = "reboot"; }
    else if (!strcmp(action, "poweroff") || !strcmp(action, "shutdown")) { path = "/sbin/poweroff"; applet = "poweroff"; }
    else if (!strcmp(action, "halt")) { path = "/sbin/halt"; applet = "halt"; }
    if (!path) return 2;
    if (geteuid() != 0) {
        fprintf(stderr, "Permission denied: run 'sudo hutos %s' as an administrator.\n", action);
        return 1;
    }
    sync();
    execl(path, applet, (char *)NULL);
    perror("hutos: cannot start system action");
    return 1;
}

static void system_menu(void) {
    char line[32];
    for (;;) {
        title("SYSTEM POWER");
        puts("  1  Restart HUTOS");
        puts("  2  Power off HUTOS");
        puts("  0  Back to toolkit");
        printf("\n  Select 0–2: "); fflush(stdout);
        if (!fgets(line, sizeof line, stdin) || line[0] == '0') return;
        const char *action = line[0] == '1' ? "restart" : line[0] == '2' ? "poweroff" : NULL;
        if (!action) { puts("  Choose 1, 2, or 0."); continue; }
        printf("  Confirm %s? [y/N]: ", action); fflush(stdout);
        if (!fgets(line, sizeof line, stdin)) return;
        if (line[0] == 'y' || line[0] == 'Y') {
            system_action(action);
            return;
        }
        puts("  Cancelled. HUTOS is still running.");
    }
}

static void beam(int argc, char **argv) {
    if (argc < 7) {
        puts("Usage: hutos mech beam L_m P_N E_Pa I_m4 [center|cantilever]");
        puts("Example: hutos mech beam 2 1000 200000000000 8e-6 center");
        return;
    }
    double L = argnum(argc, argv, 3, "span L (m)"), P = argnum(argc, argv, 4, "point load P (N)"),
           E = argnum(argc, argv, 5, "Young's modulus E (Pa)"), I = argnum(argc, argv, 6, "second moment I (m^4)");
    if (!require_positive(L,"span") || !require_positive(P,"load") || !require_positive(E,"modulus") || !require_positive(I,"second moment")) return;
    const char *kind = argc > 7 ? argv[7] : "center";
    double reaction, moment, deflection;
    if (strcmp(kind, "cantilever") == 0) {
        reaction = P; moment = P * L; deflection = P * L * L * L / (3.0 * E * I);
    } else if (strcmp(kind, "center") == 0) {
        reaction = P / 2.0; moment = P * L / 4.0; deflection = P * L * L * L / (48.0 * E * I);
    } else {
        fprintf(stderr, "Load case must be 'center' or 'cantilever'.\n"); return;
    }
    title("POINT-LOAD BEAM · LINEAR ELASTIC / EULER-BERNOULLI");
    row("Load case", strcmp(kind,"center")==0 ? "Simply supported, midspan load" : "Cantilever, tip load");
    printf("  Support reaction      %12.4g N\n", reaction);
    printf("  Maximum shear         %12.4g N\n", P);
    printf("  Maximum moment        %12.4g N·m\n", moment);
    printf("  Maximum deflection    %12.4g m  (%.4g mm)\n", deflection, deflection*1000.0);
    puts("  Assumptions: small deflection, constant E and I, static point load.");
    puts("  Educational calculation; verify boundary conditions and design factors.");
    if (strcmp(kind,"center")==0) puts("  SFD: +P/2 ──────────┐      ┌────────── -P/2");
    else puts("  SFD: V = P along span; fixed-end moment = P·L.");
}

static void stress(int argc, char **argv) {
    if (argc < 7) {
        puts("Usage: hutos mech stress F_N A_m2 extension_m original_length_m [yield_Pa]");
        puts("Example: hutos mech stress 10000 0.001 0.00025 2 250000000");
        return;
    }
    double F=argnum(argc,argv,3,"force (N)"), A=argnum(argc,argv,4,"area (m^2)"),
           dL=argnum(argc,argv,5,"extension (m)"), L=argnum(argc,argv,6,"original length (m)");
    if (!require_positive(A,"area") || !require_positive(L,"original length")) return;
    double s=F/A, strain=dL/L, young=strain != 0.0 ? s/strain : NAN;
    title("NORMAL STRESS & STRAIN · ENGINEERING CONVENTION");
    printf("  Normal stress          %.6g Pa  (%.6g MPa)\n",s,s/1e6);
    printf("  Engineering strain     %.6g  (%.6g %%)\n",strain,strain*100.0);
    printf("  Secant modulus         %.6g Pa\n",young);
    if (argc > 7) {
        double y=argnum(argc,argv,7,"yield strength (Pa)");
        if (require_positive(y,"yield strength")) printf("  Yield safety factor    %.6g\n",y/fabs(s));
    }
    puts("  Assumptions: uniform axial load and area; stress = F/A, strain = ΔL/L.");
}

static void thermo(int argc, char **argv) {
    if (argc < 6) { printf("Usage: hutos %s %s n_mol T_K V_m3\n", !strcmp(argv[1],"chem") ? "chem" : "mech", !strcmp(argv[1],"chem") ? "gas" : "thermo"); return; }
    double n=argnum(argc,argv,3,"amount (mol)"), t=argnum(argc,argv,4,"temperature (K)"), v=argnum(argc,argv,5,"volume (m^3)");
    if (!require_positive(n,"amount") || !require_positive(t,"temperature") || !require_positive(v,"volume")) return;
    double p=n*8.31446261815324*t/v;
    title("IDEAL GAS STATE");
    printf("  Pressure               %.7g Pa  (%.7g kPa)\n",p,p/1000.0);
    printf("  Equation               pV = nRT  (R = 8.314462618 J·mol⁻¹·K⁻¹)\n");
    puts("  Assumption: ideal gas; deviations grow at high pressure or near condensation.");
}

static void fluids(int argc, char **argv) {
    if (argc < 7) { puts("Usage: hutos mech fluids density_kg_m3 velocity_m_s diameter_m viscosity_Pa_s"); return; }
    double rho=argnum(argc,argv,3,"density (kg/m^3)"), v=argnum(argc,argv,4,"velocity (m/s)"),
           d=argnum(argc,argv,5,"diameter (m)"), mu=argnum(argc,argv,6,"dynamic viscosity (Pa·s)");
    if (!require_positive(rho,"density") || !require_positive(d,"diameter") || !require_positive(mu,"viscosity")) return;
    double re=fabs(rho*v*d/mu);
    title("PIPE FLOW · REYNOLDS NUMBER");
    printf("  Reynolds number        %.7g\n",re);
    printf("  Regime guide           %s\n",re < 2300 ? "laminar (Re < 2300)" : re < 4000 ? "transitional (2300–4000)" : "turbulent (Re > 4000)");
    puts("  Equation: Re = ρ|v|D/μ; circular pipe, Newtonian fluid.");
}

static int convert_unit(double v, const char *unit, double *out, const char **name) {
    struct unit { const char *u, *n; double scale, offset; };
    static const struct unit units[] = {
        {"N","force (N)",1,0},{"kN","force (N)",1000,0},{"lbf","force (N)",4.4482216153,0},
        {"Pa","pressure (Pa)",1,0},{"kPa","pressure (Pa)",1000,0},{"MPa","pressure (Pa)",1e6,0},{"bar","pressure (Pa)",1e5,0},
        {"Nm","torque (N·m)",1,0},{"J","energy (J)",1,0},{"kJ","energy (J)",1000,0},{"Wh","energy (J)",3600,0},
        {"W","power (W)",1,0},{"kW","power (W)",1000,0},{"m","length (m)",1,0},{"mm","length (m)",.001,0},{"km","length (m)",1000,0},
        {"kg","mass (kg)",1,0},{"g","mass (kg)",.001,0},{"kgm3","density (kg/m^3)",1,0},{"gcm3","density (kg/m^3)",1000,0},
        {"Pas","dynamic viscosity (Pa·s)",1,0},{"mPas","dynamic viscosity (Pa·s)",.001,0},
        {"C","temperature (K)",1,273.15},{"F","temperature (K)",5.0/9.0,255.3722222222},{"K","temperature (K)",1,0}
    };
    for (size_t i=0;i<sizeof units/sizeof units[0];i++) if (strcmp(unit,units[i].u)==0) {
        *out=v*units[i].scale+units[i].offset; *name=units[i].n; return 1;
    }
    return 0;
}

static void units(int argc,char **argv) {
    if (argc < 5) { puts("Usage: hutos mech units VALUE UNIT\nUnits: N kN lbf Pa kPa MPa bar Nm J kJ Wh W kW m mm km kg g kgm3 gcm3 Pas mPas C F K"); return; }
    double x=argnum(argc,argv,3,"value"), si; const char *n;
    if (!convert_unit(x,argv[4],&si,&n)) { fprintf(stderr,"Unknown unit '%s'. Run 'hutos mech units' for supported units.\n",argv[4]); return; }
    if (strcmp(n,"temperature (K)")==0 && si < 0.0) { fprintf(stderr,"Temperature is below absolute zero.\n"); input_error=1; return; }
    printf("%.9g %s  =  %.9g SI %s\n",x,argv[4],si,n);
}

struct element { const char *symbol; double mass; };
static const struct element elements[] = {
 {"H",1.008},{"He",4.002602},{"Li",6.94},{"Be",9.0121831},{"B",10.81},{"C",12.011},{"N",14.007},{"O",15.999},{"F",18.998403163},{"Ne",20.1797},
 {"Na",22.98976928},{"Mg",24.305},{"Al",26.9815385},{"Si",28.085},{"P",30.973761998},{"S",32.06},{"Cl",35.45},{"Ar",39.948},{"K",39.0983},{"Ca",40.078},
 {"Fe",55.845},{"Cu",63.546},{"Zn",65.38},{"Br",79.904},{"Ag",107.8682},{"I",126.90447},{"Ba",137.327},{"Au",196.966569},{"Hg",200.592},{"Pb",207.2}
};

static const char *formula;
static int formula_error;
static double parse_group(char stop);

static double element_mass(const char *s) {
    for (size_t i=0;i<sizeof elements/sizeof elements[0];i++) if (strcmp(s,elements[i].symbol)==0) return elements[i].mass;
    formula_error=1; return 0;
}

static double parse_group(char stop) {
    double total=0;
    while (*formula && *formula != stop && !formula_error) {
        double part=0;
        if (*formula=='(' || *formula=='[') {
            char close=(*formula++=='(') ? ')' : ']';
            part=parse_group(close);
            if (*formula != close) { formula_error=1; break; }
            formula++;
        } else if (isupper((unsigned char)*formula)) {
            char sym[3]={*formula++,0,0};
            if (islower((unsigned char)*formula)) sym[1]=*formula++;
            part=element_mass(sym);
        } else { formula_error=1; break; }
        double count=0;
        while (isdigit((unsigned char)*formula)) { count=count*10+(*formula-'0'); formula++; }
        total+=part*(count == 0 ? 1 : count);
    }
    return total;
}

static void molar_mass(int argc,char **argv) {
    if (argc < 4) { puts("Usage: hutos chem molar-mass FORMULA\nExample: hutos chem molar-mass Al2(SO4)3"); return; }
    formula=argv[3]; formula_error=0;
    double mass=parse_group(0);
    if (*formula || formula_error || mass<=0) { fprintf(stderr,"Cannot parse formula: supported elements include H, C, N, O, Na, Mg, Al, Si, P, S, Cl, K, Ca, Fe and more.\n"); return; }
    printf("Molar mass of %s: %.6f g/mol\n",argv[3],mass);
    puts("Atomic weights: abridged conventional values; isotopic composition can change measured sample mass.");
}

static void molarity(int argc,char **argv) {
    if (argc < 5) { puts("Usage: hutos chem molarity amount_mol volume_L"); return; }
    double n=argnum(argc,argv,3,"amount (mol)"), v=argnum(argc,argv,4,"volume (L)");
    if (!require_nonnegative(n,"amount") || !require_positive(v,"volume")) return;
    printf("Concentration: %.8g mol/L\n",n/v);
}

static void dilution(int argc,char **argv) {
    if (argc < 6) { puts("Usage: hutos chem dilution C1 V1 C2  (concentration and volume units must match)"); return; }
    double c1=argnum(argc,argv,3,"initial concentration"), v1=argnum(argc,argv,4,"initial volume"), c2=argnum(argc,argv,5,"final concentration");
    if (!require_positive(c1,"initial concentration") || !require_positive(v1,"initial volume") || !require_positive(c2,"final concentration")) return;
    printf("Final volume V2: %.8g  (same volume unit as V1)\n",c1*v1/c2);
    puts("Equation: C1·V1 = C2·V2; assumes conserved solute and additive volume.");
}

static void chem(int argc,char **argv) {
    if (argc < 3 || strcmp(argv[2],"--help")==0) { puts("Chemistry: molar-mass FORMULA | molarity mol L | dilution C1 V1 C2 | gas n T V"); return; }
    if (!strcmp(argv[2],"molar-mass")) molar_mass(argc,argv);
    else if (!strcmp(argv[2],"molarity")) molarity(argc,argv);
    else if (!strcmp(argv[2],"dilution")) dilution(argc,argv);
    else if (!strcmp(argv[2],"gas")) thermo(argc,argv);
    else fprintf(stderr,"Unknown chemistry tool '%s'.\n",argv[2]);
}

static void tools_menu(void) {
    const char *menu[] = {"System overview", "Mechanical engineering calculators", "Chemistry calculators", "System health", "Help / commands", "Restart / power off", "Exit"};
    for (;;) {
        title("ENGINEERING TOOLKIT");
        for (int i=0;i<7;i++) printf("  %s%d%s  %s\n",cyan,i+1,reset,menu[i]);
        printf("\n  Select 1–7 (or q): "); fflush(stdout);
        char line[32];
        if (!fgets(line,sizeof line,stdin)) return;
        if (line[0]=='q' || line[0]=='Q' || line[0]=='7') return;
        switch (line[0]) {
            case '1': about(0); break;
            case '2': interactive_mech(); break;
            case '3': interactive_chem(); break;
            case '4': doctor(); break;
            case '5': help(); break;
            case '6': system_menu(); break;
            default: puts("  Choose a number from 1 to 7."); break;
        }
    }
}

static void interactive_mech(void) {
    puts("\n  Mechanical tools  [1 beam · 2 stress · 3 ideal gas · 4 Reynolds · 0 back]");
    char choice[16];
    if (!fgets(choice,sizeof choice,stdin)) return;
    double a,b,c,d;
    if (choice[0]=='1') {
        if (!ask_positive("Span L (m)",&a) || !ask_positive("Midspan point load P (N)",&b) ||
            !ask_positive("Young's modulus E (Pa)",&c) || !ask_positive("Second moment I (m^4)",&d)) return;
        double r=b/2, m=b*a/4, y=b*a*a*a/(48*c*d);
        title("SIMPLY SUPPORTED BEAM · CENTER POINT LOAD");
        printf("  Reactions        %.7g N each\n  Maximum moment  %.7g N·m\n  Deflection       %.7g mm\n",r,m,y*1000);
        puts("  Assumptions: linear elastic, small deflection, constant E and I.");
    } else if (choice[0]=='2') {
        if (!ask_positive("Axial force magnitude (N)",&a) || !ask_positive("Area (m^2)",&b) ||
            !ask_positive("Original length (m)",&c)) return;
        d=ask_number("Extension (m)"); if (!isfinite(d)) return;
        title("NORMAL STRESS & ENGINEERING STRAIN");
        printf("  Stress  %.7g MPa\n  Strain  %.7g\n",a/b/1e6,d/c);
        puts("  Assumption: uniform axial load and cross-section.");
    } else if (choice[0]=='3') {
        if (!ask_positive("Amount n (mol)",&a) || !ask_positive("Temperature T (K)",&b) || !ask_positive("Volume V (m^3)",&c)) return;
        title("IDEAL GAS"); printf("  Pressure  %.7g kPa\n",a*8.31446261815324*b/c/1000);
        puts("  Equation: pV=nRT; ideal-gas assumption.");
    } else if (choice[0]=='4') {
        if (!ask_positive("Density rho (kg/m^3)",&a) || !ask_positive("Velocity v (m/s)",&b) ||
            !ask_positive("Diameter D (m)",&c) || !ask_positive("Dynamic viscosity mu (Pa.s)",&d)) return;
        title("REYNOLDS NUMBER"); printf("  Re  %.7g\n",a*b*c/d);
        puts("  Equation: Re=rho*v*D/mu; circular pipe, Newtonian fluid.");
    } else if (choice[0]!='0') puts("  Choose 1, 2, 3, 4, or 0.");
}

static void interactive_chem(void) {
    puts("\n  Chemistry tools  [1 molarity · 2 dilution · 3 ideal gas · 0 back]");
    char choice[16];
    if (!fgets(choice,sizeof choice,stdin)) return;
    double a,b,c;
    if (choice[0]=='1') {
        a=ask_number("Amount of solute (mol)"); if (!isfinite(a) || !ask_positive("Solution volume (L)",&b)) return;
        title("MOLARITY"); printf("  Concentration  %.7g mol/L\n",a/b);
    } else if (choice[0]=='2') {
        if (!ask_positive("Initial concentration C1",&a) || !ask_positive("Initial volume V1",&b) || !ask_positive("Final concentration C2",&c)) return;
        title("DILUTION"); printf("  Final volume V2  %.7g (same volume unit as V1)\n",a*b/c);
        puts("  Equation: C1*V1=C2*V2; assumes solute is conserved.");
    } else if (choice[0]=='3') {
        if (!ask_positive("Amount n (mol)",&a) || !ask_positive("Temperature T (K)",&b) || !ask_positive("Volume V (m^3)",&c)) return;
        title("IDEAL GAS"); printf("  Pressure  %.7g kPa\n",a*8.31446261815324*b/c/1000);
    } else if (choice[0]!='0') puts("  Choose 1, 2, 3, or 0.");
}

int main(int argc,char **argv) {
    colors_init();
    if (argc < 2 || !strcmp(argv[1],"help") || !strcmp(argv[1],"--help") || !strcmp(argv[1],"-h")) { help(); return 0; }
    if (!strcmp(argv[1],"--plain")) {
        color=0; cyan=blue=green=amber=red=muted=reset="";
        if (argc == 2) { help(); return 0; }
        argc--; argv++;
    }
    if (!strcmp(argv[1],"about")) { about(0); return 0; }
    if (!strcmp(argv[1],"info")) { about(1); return 0; }
    if (!strcmp(argv[1],"version")) { struct utsname u; uname(&u); printf("HUTOS 3.1.0 · Linux %s · %s\n",u.release,u.machine); return 0; }
    if (!strcmp(argv[1],"update")) { execl("/bin/apt","apt","update",(char *)NULL); perror("hutos: cannot start apt"); return 1; }
    if (!strcmp(argv[1],"doctor")) return doctor();
    if (!strcmp(argv[1],"restart") || !strcmp(argv[1],"reboot") ||
        !strcmp(argv[1],"poweroff") || !strcmp(argv[1],"shutdown") ||
        !strcmp(argv[1],"halt")) return system_action(argv[1]);
    if (!strcmp(argv[1],"tools")) { tools_menu(); return 0; }
    if (!strcmp(argv[1],"mech")) {
        if (argc<3 || !strcmp(argv[2],"--help")) { puts("Mechanical tools: beam | stress | thermo | fluids | units"); return 0; }
        if (!strcmp(argv[2],"beam")) beam(argc,argv);
        else if (!strcmp(argv[2],"stress")) stress(argc,argv);
        else if (!strcmp(argv[2],"thermo")) thermo(argc,argv);
        else if (!strcmp(argv[2],"fluids")) fluids(argc,argv);
        else if (!strcmp(argv[2],"units")) units(argc,argv);
        else { fprintf(stderr,"Unknown mechanical tool '%s'.\n",argv[2]); return 2; }
        return input_error ? 2 : 0;
    }
    if (!strcmp(argv[1],"chem")) { chem(argc,argv); return input_error ? 2 : 0; }
    fprintf(stderr,"Unknown command '%s'. Run 'hutos help'.\n",argv[1]);
    return 2;
}
