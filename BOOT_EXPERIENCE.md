# HUT OS Boot Experience Preview

## What You'll See When HUT OS Boots

---

## 🚀 Stage 1: Kernel Boot Messages

```
SeaBIOS (version 1.17.0-debian-1.17.0-1ubuntu1)
iPXE (https://ipxe.org) 00:03.0 CA00 PCI2.10 PnP PMM
Booting from ROM...

[    0.000000] Linux version 7.3.0-rc5-HUTOS-Hamedan-University-of-Technology
[    0.000000] Command line: console=ttyS0
[    0.000000] BIOS-provided physical RAM map...
...
[    2.226005] Freeing unused kernel image (initmem) memory: 2916K
[    2.349164] x86/mm: Checked W+X mappings: passed
[    2.349844] Run /init as init process
```

---

## 🎨 Stage 2: HUT OS Boot Sequence (Custom Init)

### Boot Header
```
╔═══════════════════════════════════════════════════════════╗
║                 HUT OS Boot Sequence                      ║
╚═══════════════════════════════════════════════════════════╝
```

### System Initialization
```
[INFO] Initializing HUT OS...
[ OK ] Process filesystem mounted
[ OK ] System filesystem mounted
[ OK ] Device filesystem mounted
[ OK ] BusyBox userspace initialized
[ OK ] Kernel modules loaded
[ OK ] HUT OS is ready
```

*(Colors: INFO in cyan, OK in green)*

---

## 🎭 Stage 3: HUT ASCII Art Banner

```
═══════════════════════════════════════════════════════════

                         █████████████████████████████████████████████████                          
                            ███████████████████████████████████████████                             
                               █████████████████████████████████████                                
                   ██            █████████████████████████████████            ██                    
                   ██               ████████████████████████████              ███                   
                  ███                 ████████████████████████                ███                   
                  ████                 █████████████████████                  ████                  
                  ████                  ███████████████████                  █████                  
                  █████                   ████████████████                   █████                  
                  ███████                  ██████████████                  ███████                  
                   ███████                  ████████████                 ████████                   
                    █████████                ██████████                █████████                    
                     ██████████               ████████              ███████████                     
                       ████████████           ████████           ████████████                       
                         █████████████         ██████         █████████████                         
               █           ███████████████      ████      ██████████████            █               
         █████████████        ██████████████     ██     █████████████        █████████████          
      █████████████████████      ██████████████  ██  ██████████████      ████████████████████       
    ██████████████████████████      ███████████      ██████████       ██████████████████████████    
  ████            ████████████████      ██████   █    ██████      ███████████████            ████   
  █                    ██████████████           ████           ██████████████                    █  
                          █████████████        ██████       ██████████████                          
                            ██████████████    ████████    █████████████                             
                                █████████   ███████████   ██████████                                
████                               █████   ██████████████  █████                                ███ 
 ██████                                   ████████████████                                   █████  
  █████████                          ███                   ███                           ████████   
   █████████████████████████████████████                    ████████████████████████████████████    
    ██████████████████████████████████   ███████    ███████  ██████████████████████████████████     
     ████████████████████████████████    ███████    ███████    ███████████████████████████████      
       ████████████████████████████      ███████    ███████      ████████████████████████████       
        ██████████████████████████       ███████    ███████       ██████████████████████████        
         ███████████████████████         ███████    ███████        ████████████████████████         
          █████████████████████          ███████    ███████         ██████████████████████          
           ███████████████████           ███████    ███████           ███████████████████           
            █████████████████            ███████    ███████            █████████████████            
             ███████████████             ███████    ███████             ███████████████             
              █████████████              ███████    ███████             ██████████████              
               ███████████               ███████    ███████              ████████████               
                ██████████               ███████    ███████               ██████████                
                 ████████               ███████     ███████               █████████                 
                  ███████               ███████      ███████              ████████                  
                   ██████               ██████       ███████               ██████                   
                    █████              ██████         ███████              ████                     
                      ███             ██████           ███████             ███                      
                       ██           ██████               ███████           ██                       
                        █        ███████                    ███████        █                        
                               █████                            █████                               
```

---

## 💎 Stage 4: Welcome Screen

```
════════════════════════════════════════════════════════════
                          H U T   O S                       
              Hamedan University of Technology              
════════════════════════════════════════════════════════════

             Welcome to HUT Operating System                

         A minimal Linux-based OS, built from scratch       
            in a university dormitory study hall.           

────────────────────────────────────────────────────────────
  Developer:  Arshia Mohammadei
  GitHub:     https://github.com/itashia
  Field:      Mechanical Engineering - 2nd Semester
────────────────────────────────────────────────────────────

  "One day I was sitting in the dormitory study hall,
   had nothing better to do, and started building my own
   operating system.

   And what better name could it have than our university?

   Welcome to HUT OS."

════════════════════════════════════════════════════════════

System ready. Type about for more information.
```

*(Colors: Title in white, headings in white, text in cyan, quote in dim gray)*

---

## 🖥️ Stage 5: Interactive Shell

```
BusyBox v1.37.0 (Ubuntu 1:1.37.0-7ubuntu1) built-in shell (ash)
Enter 'help' for a list of built-in commands.

hut@hut-os:~# 
```

*(Prompt colors: "hut@hut-os" in cyan, "~" in blue, "#" default)*

---

## 📖 The `about` Command

Type `about` at the prompt to see:

```
╔══════════════════════════════════════════════════════════════╗
║                         H U T   O S                          ║
║             Hamedan University of Technology                 ║
╚══════════════════════════════════════════════════════════════╝

Operating System
  HUT OS - Hamedan University of Technology Operating System

Base
  Custom Linux Kernel
  BusyBox Userspace
  Minimal Initramfs

University
  Hamedan University of Technology

────────────────────────────────────────────────────────────

Developer Information

  Name:      Arshia Mohammadei
  GitHub:    https://github.com/itashia
  Field:     Mechanical Engineering
  Semester:  2nd Semester (at project start)

────────────────────────────────────────────────────────────

The Story

  One day, sitting in the dormitory study hall with nothing
  better to do, I decided to build my own operating system.

  As a second-semester mechanical engineering student at
  Hamedan University of Technology, I wondered:

  "What better name than our university?"

  And so, HUT OS was born.

  Built from scratch using:
    • Custom Linux kernel configuration
    • BusyBox minimal userspace
    • Hand-crafted initramfs
    • Pure determination and curiosity

  This isn't just an OS. It's a testament to what you can
  achieve when you have time, curiosity, and access to
  a quiet study hall.

════════════════════════════════════════════════════════════

        Proudly built at Hamedan University of Technology

════════════════════════════════════════════════════════════

Kernel Version
Linux version 7.3.0-rc5-HUTOS-Hamedan-University-of-Technology ...

Type 'exit' to power down, or continue exploring HUT OS.
```

---

## 🎨 Color Scheme Reference

Throughout HUT OS, you'll see:

- **Cyan** (`#00FFFF`) - Primary branding, headers, "HUT OS" text
- **Green** (`#00FF00`) - Success states, "[ OK ]", confirmations
- **White** (`#FFFFFF`) - Main headings, important text
- **Blue** (`#0000FF`) - Paths, working directory in prompt
- **Dim Gray** - Quotes, secondary information

---

## ⌨️ Common Commands

Once you're at the prompt:

```bash
about          # Show system information
help           # BusyBox built-in commands
ls             # List files
cat /etc/hut-banner.txt    # View the ASCII banner again
uname -a       # Kernel information
free           # Memory usage
mount          # Show mounted filesystems
ps             # Running processes
```

---

## 🚪 Exiting HUT OS

To exit QEMU:

1. Press `Ctrl+A` (release)
2. Then press `X`

Or type `poweroff` at the shell (if configured).

---

## 📸 Screenshots

*Terminal output will show:*
- Colored text (cyan, green, white)
- Box-drawing characters (╔, ═, ╗, etc.)
- ASCII art banner
- Custom prompt with colors

*Best viewed in:*
- Modern terminal emulators
- Terminals with 256-color support
- xterm, GNOME Terminal, iTerm2, Windows Terminal, etc.

---

## 🎭 The Experience

HUT OS boot feels like:

```
BIOS POST
    ↓
Unix terminal boot
    ↓
University laboratory system
    ↓
Student hacker project
    ↓
Personal operating system
```

It's **geeky**, **polished**, **memorable**, and proudly displays **HUT** identity!

---

*Proudly built at Hamedan University of Technology* 🎓

**Developer:** Arshia Mohammadei  
**GitHub:** [@itashia](https://github.com/itashia)  
**Version:** 2.0.0
