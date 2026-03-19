# Kaspa Launcher

A menu-driven launcher for Kaspa executables with persistent saved arguments. Available for Windows and Mac/Linux.

---

## Files

| File | Platform |
|---|---|
| `launch-kaspa-win64.bat` | Windows |
| `launch-kaspa.command` | Mac / Linux |
| `config-kaspa.txt` | Windows config (auto-created) |
| `config-kaspa.conf` | Mac/Linux config (auto-created) |

---

## Getting the Executables

The Kaspa executables are available in the latest release of the official [rusty-kaspa](https://github.com/kaspanet/rusty-kaspa) repository.

**Latest release: [v1.1.0](https://github.com/kaspanet/rusty-kaspa/releases/tag/v1.1.0)**

Download the appropriate archive for your platform, extract the executables, and place them in the same folder as the launcher script.

---



1. Place the launcher script in the **same folder** as your Kaspa executables
2. Double-click to run — no installation needed
3. The config file is created automatically on first launch

> **Mac/Linux only:** If the `.command` file won't open, make it executable first:
> ```bash
> chmod +x launch-kaspa.command
> ```

---

## Main Menu

```
1. kaspad.exe         (Node)
2. kaspa-wallet.exe   (Wallet)
3. rothschild.exe     (Stress Test)
4. stratum-bridge.exe (Mine to Node)
5. Manage arguments
6. Exit
```

Press **Enter** to default to option 1 (kaspad).

---

## Managing Arguments

Select option **5** from the main menu, then choose an executable. From there you can:

### Add argument
Type a number for a quick preset, or type any argument directly.

Presets:
```
1. --retention-period-days=2
2. --ram-scale=0.5
3. --disable-upnp
4. --utxoindex
5. --appdir C:\path\to\SSD\storage
```

For arguments with a path (like `--appdir`), type the full argument including your path:
```
--appdir C:\Users\yourname\AppData\Local\kaspa
```

### Remove argument
Arguments are listed by number. Type the number of the argument you want to remove and confirm.

### Clear all arguments
Removes all saved arguments for the selected executable.

### View available arguments
Runs the executable with `-h` to show all supported arguments.

---

## Config File Format

Arguments are stored using `==` as a delimiter to safely support arguments that contain spaces (like `--appdir` with a path):

```
kaspad.exe=--retention-period-days=2==--ram-scale=0.5==--appdir C:\path\to\data
kaspa-wallet.exe=
rothschild.exe=
stratum-bridge.exe=
```

> If you have an older config file using space-separated arguments, the launcher will automatically detect and convert it to the `==` format on first open.

---

## Stopping a Running Process

Press **Ctrl+C** in the terminal window to stop any running Kaspa process. The launcher will return to the main menu automatically.

---

## Common Arguments

| Argument | Description |
|---|---|
| `--retention-period-days=2` | Prune block data older than N days |
| `--ram-scale=0.5` | Scale RAM usage (e.g. 0.5 = 50%) |
| `--utxoindex` | Enable UTXO index |
| `--disable-upnp` | Disable UPnP port mapping |
| `--appdir C:\path` | Custom data directory |
| `--perf-metrics` | Enable performance metrics |

For a full list of supported arguments, use option **4** (View available arguments) inside the manage menu.
