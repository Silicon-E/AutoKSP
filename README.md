# AutoKSP
Scripts for fully-automatic control of Kerbal Space Program spacecraft using the Kerbal OS mod.
Structure
- A script performing a mission should only have to call runpath("0:/AutoKSP/lib_navigation.ks"). That script should contain the code used to interface with AutoKSP.
- With the exception of lib_navigation.ks, code that guides the ship through a single task and then returns should be in its own script rather than a library function.
Contributing (This is a private project.)
- Pushed code should run without errors.
- Keep style consistent within any single file. Style may differ between files.
