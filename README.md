# forest-env

Environment-only Docker image for the LiDAR tree segmentation project (PTv3 / SpConv).
The image contains **only the software environment** – no project code, no data.

```
ghcr.io/slowiklukasz/forest-env:latest
```

---

## What's inside

| Component | Version / notes |
|---|---|
| Base image | `pytorch/pytorch:2.1.0-cuda12.1-cudnn8-devel` |
| Python | 3.10 |
| PyTorch | 2.1.0, CUDA 12.1, cuDNN 8 |
| NumPy | `>=1.19.5,<1.27.0` |
| spconv | `spconv-cu120` |
| PyG | `torch-scatter`, `torch-sparse`, `torch-cluster` (wheels for torch-2.1.0+cu121), `torch-geometric` |
| Pointcept | cloned to `/opt/Pointcept`, compiled `pointops` and `pointgroup_ops` |
| PTv3 standalone | cloned to `/opt/PTv3_Standalone` |
| Other | `laspy[lazrs]`, `torchmetrics`, `pandas`, `open3d==0.19.0`, `seaborn==0.13.2`, `wandb`, `timm`, `einops`, `scipy`, `h5py`, … |
| Jupyter | `jupyterlab`, `ipykernel` |

`PYTHONPATH=/opt/Pointcept/Pointcept:/opt/PTv3_Standalone` is set in the image,
so **no `sys.path.insert(...)` is needed** in notebooks. Use the default `Python 3` kernel.

Default working directory: `/notebooks`.

---

## Supported GPUs

CUDA extensions are compiled with `TORCH_CUDA_ARCH_LIST="7.5;8.0;8.6"`:

| Compute capability | Examples |
|---|---|
| 7.5 (Turing) | Quadro RTX 5000 (Paperspace Free-RTX5000), RTX 20xx, T4 |
| 8.0 (Ampere) | A100 |
| 8.6 (Ampere) | RTX 30xx, A4000/A5000/A6000 |

Not covered out of the box:
- **P5000 / Pascal (6.1)** – add `6.1` to the list and rebuild.
- **RTX 40xx (8.9)** – add `8.9` and rebuild.
- **RTX 50xx (12.0)** – needs CUDA 12.8+ and a newer PyTorch (different base image).

Check your GPU:
```bash
nvidia-smi --query-gpu=name,compute_cap --format=csv
```

FlashAttention is **not installed** (not supported on Turing). Run PTv3 with `enable_flash=False`.

---

## How the image is built

- `Dockerfile` in this repo describes the environment.
- `.github/workflows/docker.yml` builds it on GitHub Actions on every push to `main`
  (or manually: *Actions → Build Docker image → Run workflow*) and pushes it to GHCR.
- Build takes ~15 min. The package is set to **Public**, so no login is needed to pull it.

To change the environment: edit `Dockerfile` → commit → push → wait for the green Action → restart the notebook / re-pull the image.

---

## Usage on Paperspace Gradient

1. **Create notebook** → template **Start from Scratch**.
2. Machine: **Free-RTX5000**.
3. **View advanced options**:
   - Workspace: leave empty
   - Container Name: `ghcr.io/slowiklukasz/forest-env:latest`
   - Registry username / password: leave empty
   - Command: keep the default (`... jupyter lab --allow-root --ip=0.0.0.0 ...`)
4. Start. The first start shows *Setting up image* for a few minutes (image pull). A *NetworkError* popup during startup is normal.

Notes:
- `/notebooks` is per-notebook persistent storage (empty at start – nothing from the image lives there).
- `/storage` is persistent storage that can be shared between notebooks – use it to move data.

---

## Local usage

Requirements:
- **Windows:** Docker Desktop with WSL2 backend + recent NVIDIA driver.
- **Linux:** Docker + NVIDIA driver + [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html).

Pull the image (~10+ GB):
```bash
docker pull ghcr.io/slowiklukasz/forest-env:latest
```

Quick GPU check:
```bash
docker run --rm --gpus all ghcr.io/slowiklukasz/forest-env:latest nvidia-smi
```

Run Jupyter with a local project folder mounted as `/notebooks`:

**PowerShell (Windows):**
```powershell
docker run --gpus all -it --rm -p 8888:8888 `
  -v C:\projects\forest:/notebooks `
  ghcr.io/slowiklukasz/forest-env:latest `
  jupyter lab --ip=0.0.0.0 --allow-root --no-browser
```

**Linux:**
```bash
docker run --gpus all -it --rm -p 8888:8888 \
  -v ~/projects/forest:/notebooks \
  ghcr.io/slowiklukasz/forest-env:latest \
  jupyter lab --ip=0.0.0.0 --allow-root --no-browser
```

Open the printed link `http://127.0.0.1:8888/lab?token=...` in the browser.

- Everything written to `/notebooks` lands in the mounted local folder; everything else is lost when the container stops (`--rm`).
- Shell instead of Jupyter: replace the last line with `bash`.
- Without an NVIDIA GPU the container starts, but spconv and the CUDA extensions won't work.

---

## Pinned versions (`constraints.txt`)

`constraints.txt` lists the exact package versions installed in the current image.
It is generated inside the running container:

```bash
pip list --format=freeze > /notebooks/constraints.txt
```

(`pip list --format=freeze`, not `pip freeze` – the latter prints `@ file:///...` paths for conda packages.)

Use it to install a CPU-only subset with matching versions, e.g. for local data processing without Docker:

```powershell
python -m venv .venv
.venv\Scripts\activate
pip install -e .[processing] -c https://raw.githubusercontent.com/slowiklukasz/forest-env/main/constraints.txt
```

Constraints only pin versions – packages not requested (spconv, pointops, CUDA libs) are not installed.

**Rule:** every change of `Dockerfile` → wait for the build → regenerate `constraints.txt` in the new container → commit.

---

## Verify the environment

```bash
python -c "import torch; print(torch.__version__, torch.cuda.is_available(), torch.cuda.get_device_name(0))"
python -c "import pointops, pointgroup_ops, torch_scatter, torch_cluster, torch_sparse, spconv; print('OK')"
```

Expected (Gradient): `2.1.0 True Quadro RTX 5000` and `OK`.

---

## TODO

- Optionally pin key unpinned packages directly in the `Dockerfile` (versions from `constraints.txt`), so rebuilds are fully reproducible.
