# HUTOS engineering command tools

HUTOS provides a small native C command, `hutos`, built statically from
[`src/hutos.c`](../src/hutos.c). It uses procfs/syscalls for live system values
and libc/libm for calculations. No Python, Bash, ncurses, GUI, or network
service is required.

## System commands

```sh
hutos about       # compact system and engineering dashboard
hutos info        # expanded runtime details
hutos doctor      # mounts, memory, CPU, package state, login supervisor
hutos restart     # restart the computer (root required)
hutos poweroff    # power off the computer (root required)
hutos halt        # halt the computer (root required)
hutos tools       # numbered interactive engineering menu
hutos version
hutos help
hutos update      # forwards to apt update
```

The interactive toolkit includes a **Restart / power off** submenu. It asks
for confirmation before running either action. Direct power commands act
immediately and require root privileges; use `sudo hutos restart` or
`sudo hutos poweroff` from an administrator account.

Set `NO_COLOR=1` or use `hutos --plain about` for monochrome output. The
welcome line in `.zshrc` is suppressed with `HUTOS_NO_WELCOME=1` or by creating
`~/.config/hutos/no-welcome`.

## Mechanical engineering

```sh
hutos mech beam 2 1000 200000000000 8e-6 center
hutos mech beam 2 1000 200000000000 8e-6 cantilever
hutos mech stress 10000 0.001 0.00025 2 250000000
hutos mech thermo 1 300 0.024465
hutos mech fluids 1000 1 0.05 0.001
hutos mech units 32 F
```

Beam inputs are span in m, point load in N, Young's modulus in Pa, and area
second moment in m⁴. `center` is a simply supported beam with a central point
load; `cantilever` is a tip-loaded cantilever. Results use Euler-Bernoulli,
linear-elastic, small-deflection assumptions. Stress uses axial `F/A`,
engineering strain `ΔL/L`, and an optional yield stress for `Sy/|σ|`.
Thermodynamics uses `pV=nRT`; fluids reports `Re=ρ|v|D/μ` and the conventional
pipe-flow regime guide. Units converts supported force, pressure, torque,
energy, power, temperature, length, mass, density, and dynamic-viscosity units
to SI.

## Chemistry

```sh
hutos chem molar-mass 'Al2(SO4)3'
hutos chem molarity 0.5 2
hutos chem dilution 2 0.1 0.5
hutos chem gas 1 298.15 0.024
```

The formula parser supports element counts and nested `()` / `[]` groups. Its
abridged atomic-weight table covers common elements; it is not an isotope or
laboratory reference database. Molarity expects amount in mol and volume in L.
Dilution expects compatible concentration and volume units and assumes the
solute amount is conserved. Gas calculations use the ideal-gas assumption.

## Current scope

The beam, stress, ideal-gas, Reynolds, unit, formula-mass, molarity, and
dilution calculations have known-reference checks in `./test-hutos-science.sh`.
The interactive menu currently provides prompted beam, stress, ideal-gas,
Reynolds, molarity, and dilution paths. Chemistry balancing, periodic table,
materials database, matrix/vector/statistics tools, and physics calculators are
not implemented yet. The dashboard does not imply those tools are present.

These commands are educational calculators. They do not replace engineering
design codes, material certification, uncertainty analysis, or independent
design review.
