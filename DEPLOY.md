# Deploying Sthāna on Render

The repo includes a `Dockerfile` and a `render.yaml` Blueprint. Render builds the image,
runs `gunicorn` with **one worker** (live seats, timers and the video player live in memory),
and gives you an `https://<name>.onrender.com` URL.

## 1. Prepare the repo

```
seat_monitor/
├── models/     weights_deskDetection.pt, weights_objectDetection.pt, yolov8n.pt   <- must be committed
├── data/       2-5 sample photos of the hall (they appear in the "Data folder" dropdown)
├── Dockerfile, render.yaml, requirements.txt, .gitignore, .dockerignore
└── ...
```

- GitHub rejects files over **100 MB**. YOLO nano/small weights are well under that; check yours.
- Use a **private** GitHub repo: the photos show students. Render deploys private repos fine.
- `outputs/`, `uploads/` and `batch_outputs/` are git-ignored on purpose.

```bash
cd seat_monitor
git init
git add .
git commit -m "Sthana: library seat monitor"
git branch -M main
git remote add origin https://github.com/<you>/sthana.git
git push -u origin main
```

## 2. Create the service

**Option A: Blueprint (uses render.yaml)**
1. Render dashboard → **New → Blueprint** → pick the repo.
2. Enter a value for `SITE_PASSWORD` when asked (or leave it empty for an open site).
3. **Apply**. The first build takes about 10 minutes (it installs CPU-only PyTorch).

**Option B: by hand**
1. **New → Web Service** → pick the repo → Language/Runtime: **Docker**.
2. Instance type: **Standard (2 GB)**.
3. Health check path: `/healthz`.
4. Environment variables: `OUTPUT_DIR=/var/data/outputs`, `UPLOAD_DIR=/var/data/uploads`, optional `SITE_PASSWORD`.
5. **Advanced → Add Disk**: mount path `/var/data`, 1 GB.

## 3. Check it

- `https://<name>.onrender.com/healthz` → `{"ok": true}`
- Open the site → **Live** → pick a photo from *Data folder* → **Analyze**.
- If you set `SITE_PASSWORD`, the browser asks for it (any username works).

## Plans and memory

| Plan | RAM | Works? |
|---|---|---|
| Free | 512 MB | Likely runs out of memory with three models loaded. Also sleeps after 15 min idle (~1 min + model load to wake), and has no disk, so history is lost on every restart. |
| Starter ($7) | 512 MB | Same memory risk. |
| **Standard ($25)** | **2 GB** | Recommended. Pay only for the days you need it, then suspend the service. |

If a deploy fails with "Out of memory" in the Render Events tab, move to a bigger instance.

**Free alternative with more memory:** Hugging Face Spaces (CPU Basic: 2 vCPU, 16 GB RAM, free, sleeps when idle).
Create a *Docker* Space, push the same repo, and add `app_port: 10000` to the Space's README header.
No persistent history there either.

## Things that behave differently on a server

- **Camera frame / Live camera** need a webcam on the machine running the app, so they won't work on Render. Use image upload, the data folder, or video upload.
- **Uploads** are capped at `MAX_UPLOAD_MB` (default 200 MB).
- **Without a disk**, History, Records and the Map time-lapse reset whenever the service restarts or redeploys.
- **Speed**: roughly one CPU, so each photo takes a few seconds (three models). For video, use *Analyze every* 5-10 s and speed 1-2×.
- For the hackathon demo, record a video of the live site as a backup (the brief says recorded is safer).

## Environment variables

| Variable | Default | Purpose |
|---|---|---|
| `PORT` | 10000 (Docker) | Set by Render automatically |
| `OUTPUT_DIR` | `./outputs` | Runs, crops, CSVs. Point at the disk: `/var/data/outputs` |
| `UPLOAD_DIR` | `./uploads` | Uploaded videos |
| `IMAGE_DIR` | `./data` | Sample frames shown in the Data folder dropdown |
| `MODEL_DIR` | `./models` | The three `.pt` files |
| `SITE_PASSWORD` | unset | Browser password prompt for the whole site |
| `MAX_UPLOAD_MB` | 200 | Upload size limit |
