# ELOS6.1

**Enhanced Lightweight Operating System v6.1**

It's part of the ELOS operating system family, which was
created in august 2025, where ELOS6 was begun in July 2026
and the latest version, a "branch" from ELOS6, begun in
August of the same year

A tiny x86 IA-32 Operating System written entirely in Assembly.

It's an experiment in building an operating system from the
ground up as it doesn't run on top of Linux/GRUB; whilst
keeping the system small, and understandable.

# General Data

## Minimum Requirements

- 80386+/IA-32 Compatible CPU
- 1.1 MB RAM Minimum
- VGA/VESA-compatible display
- PS/2 Keyboard/Mouse (working on PCI USB drivers)

## Building

```sh
./run.sh # Assembles and Runs the binary
```

# Evolution + Some history

## ELOS6

This was one of the first GUI outputs had which is now the
base of the whole windowing system...

![First Window](docs/img/first_window.png)
![Second Window](docs/img/test_wnd2.png)

This windowing system was actually built on top of the idea
that came from ELOS2 (an idea discarded in November 2025,
due to very few modularity), funnily, the font comes back
from ELOS1 (discarded in August 2025 due to unstability).

![First Print](docs/img/first_print.png)
![Second Print](docs/img/first_print2.png)

The font was brought back from then because I personally
didn't want to spend another 6 hours making another bitmap
font manually!

![First Button](docs/img/first_btn.png)
![Second Button](docs/img/clear_btn.png)

And this is very probably the last ELOS version that will be
made as I feel proud myself, of the modularity and the
architecture I got out of this...

![First Calc](docs/img/calc_1.png)
![Second Calc](docs/img/calc_2.png)

The calculator was one of the first ideas I got to test the
GUI ABI and so it was the first GUI app (altough not
functional) made on ELOS6... altough it got to be the first
userland application ran :D

![Cyan](docs/img/cyan.png)

I changed the background color to cyan because I wanted to
copy Windows 95 (silly me...), but in the end I got feedback
about it being too light (which came with ELOS6.1 which
we'll see later on) :/

![Square](docs/img/square.png)

And I also finished the calculator GUI (which added the
square and the button).

![First Exc](docs/img/exception.png)
![Second Exc](docs/img/exception_2.png)

I did take a lot of photos on the way (and some of them are
simply lost to my computer but can be found in messages,
which I won't be bothered to search).

## ELOS6.1

Here we get to ELOS6.1, which is simply a better (and fuller)
version of ELOS6 that added userland applications and a top
status bar showing the hour and some shortcuts to start
applications

![Bug](docs/img/bug_2wnd.png)
![Top Winver](docs/img/clock_winver.png)

Then I added a filesystem (which had been in development since I was finishing ELOS6) and added an app to look up to
it, and fixed the bug we saw just earlier.

![Explorer](docs/img/explorer.png)
![Fix bug](docs/img/2wnd.png)

I also added background stuff as a PCI driver loader which
as of now, is broken; and fixed a LOT of bugs I found on the
way...

![Notepad](docs/img/notepad.png)
![Notepad_SCA](docs/img/notepad_sca.png)

And I added a notepad (shortly after I fixed a bug) and then
I added keybind access, so like Shift+x making an uppercase
X and Shift+1 making an exclamation mark...
