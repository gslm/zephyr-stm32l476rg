# zephyr-stm32

Sandbox space for Zephyr firmware experiments on the STM32 Nucleo boards.

Currently tested on STM32L476RG. The sample currently ships with a modified `blinky` (`SLEEP_TIME_MS = 100 ms`) under `app/`.

## Prerequisites

1. Follow the [Zephyr Getting Started Guide](https://docs.zephyrproject.org/latest/develop/getting_started/index.html) on the target machine. After `west init`/`west update` you should have a workspace similar to:
   ```
   ~/Zephyr/
   ├─ zephyr                 # Zephyr source tree from west
   ├─ modules, bootloader…   # other west-managed projects
   └─ zephyr-stm32           # this repository (cloned manually)
   ```
2. Create (or reuse) a Python virtual environment inside `~/Zephyr` and install Zephyr’s tool requirements:
   ```bash
   cd ~/Zephyr
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r zephyr/scripts/requirements.txt
   ```
3. Clone this repository next to the Zephyr tree:
   ```bash
   cd ~/Zephyr
   git clone git@github.com:<your-org>/zephyr-stm32.git
   ```

> The repository does **not** duplicate the Zephyr source; builds consume headers/modules directly from `~/Zephyr/zephyr`.

## Building and flashing

Example for a NUCLEO STM32L$76RG board.

```bash
cd ~/Zephyr
source zephyr/zephyr-env.sh          # or: source .venv/bin/activate
cd zephyr-stm32
west build -p auto -b nucleo_l476rg app -d build
west flash -d build
```

- `app/` contains `CMakeLists.txt`, `prj.conf`, and `src/main.c`.
- `-d build` keeps artifacts inside this repo; ensure `build/` stays untracked (see `.gitignore`).
- Re-run `pip install -r …` whenever Zephyr updates its Python requirements.

### Helper script

Use `./run` to wrap the usual `west` commands:

```
./run          # build + flash (default)
./run -c       # clean only (west build -t pristine)
./run -b       # build only
./run -f       # flash the existing build
./run -bc      # clean + build
./run -bf      # build + flash
./run -a       # clean + build + flash + prepare VS Code env (-cbfd)
./run -d       # refresh VS Code debug environment file
./run -e       # drop into an interactive shell with the Zephyr env
./run -cbf     # clean + build + flash (legacy default); flags may be combined
```

Run `./run -h` to print the usage text.

## Customizing the application

- Edit `app/src/main.c` to change GPIO behavior, logging, etc. The current sample prints the LED state and toggles every 100 ms.
- Add Kconfig options to `app/prj.conf`.
- Place board-specific Device Tree overlays in `app/boards/arm/nucleo_l476rg.overlay`. The merged DTS appears in `build/zephyr/zephyr.dts` for inspection only—do not edit generated files.

To experiment with other samples, copy their `CMakeLists.txt`, `prj.conf`, and `src/` into a new folder (e.g., `uart_demo/`) and point West at it:

```bash
west build -p auto -b nucleo_l476rg uart_demo -d build-uart
```

## IDE integration (VS Code)

1. Install the official C/C++ extension.
2. Open the `~/Zephyr` workspace (so both the Zephyr tree and this repo are visible).
3. Set the compile commands database for IntelliSense via `.vscode/c_cpp_properties.json`:
   ```json
   {
     "configurations": [
       {
         "name": "Linux",
         "compileCommands": "${workspaceFolder}/zephyr-stm32/build/compile_commands.json"
       }
     ],
     "version": 4
   }
   ```
4. After running `west build … -d build`, VS Code can `Ctrl+Click` into symbols like `k_msleep`.

## Typical workflow

1. Edit sources/config/overlays inside this repo.
2. `west build` / `west flash` using the commands above.
3. Inspect `build/zephyr/zephyr.dts` or `build/zephyr/zephyr.elf` as needed.
4. Commit only project sources/configuration (exclude `build/`).

Keeping Zephyr upstream under `~/Zephyr/zephyr` and your experiments here allows you to update Zephyr via `west update` without disrupting local projects.
