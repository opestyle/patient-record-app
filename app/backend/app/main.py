from contextlib import asynccontextmanager
from typing import List

from fastapi import Depends, FastAPI, File, HTTPException, UploadFile, status
from fastapi.responses import HTMLResponse
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from . import auth, config
from .db import Base, engine, get_db
from .models import Patient, User
from .s3_utils import UploadError, upload_to_s3
from .schemas import PatientCreate, PatientRead, Token

# Table creation via metadata is a dev-only convenience. Real environments
# apply the Alembic migrations (see migrations/) as part of the container
# startup command instead, so schema changes are tracked and repeatable.
if config.APP_ENV == "dev":
    Base.metadata.create_all(bind=engine)


@asynccontextmanager
async def lifespan(app: FastAPI):
    auth.bootstrap_admin_user()
    yield


app = FastAPI(title="Patient Records App", version="1.0.0", lifespan=lifespan)


@app.get("/api/health", tags=["health"])
def health_check() -> dict:
    return {"status": "ok", "service": "patient-records-api"}


@app.get("/", response_class=HTMLResponse, tags=["ui"])
def index() -> str:
    return """
    <html>
      <body style='font-family: sans-serif; padding: 2rem;'>
        <h1>Patient Records Portal</h1>
        <p>Use the API endpoints to manage patients and upload documents.</p>
        <ul>
          <li>/api/health</li>
          <li>/api/patients</li>
          <li>/api/upload</li>
        </ul>
      </body>
    </html>
    """


@app.post("/api/auth/login", response_model=Token, tags=["auth"])
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)) -> Token:
    user = auth.authenticate_user(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return Token(access_token=auth.create_access_token(subject=user.email))


@app.post("/api/patients", response_model=PatientRead, tags=["patients"])
def create_patient(
    payload: PatientCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(auth.get_current_user),
) -> PatientRead:
    patient = Patient(**payload.model_dump())
    db.add(patient)
    db.commit()
    db.refresh(patient)
    return patient


@app.get("/api/patients", response_model=List[PatientRead], tags=["patients"])
def list_patients(
    db: Session = Depends(get_db),
    current_user: User = Depends(auth.get_current_user),
) -> List[PatientRead]:
    return db.query(Patient).order_by(Patient.created_at.desc()).all()


@app.post("/api/upload", tags=["uploads"])
def upload_file(
    file: UploadFile = File(...),
    current_user: User = Depends(auth.get_current_user),
) -> dict:
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file selected")

    contents = file.file.read()
    try:
        url = upload_to_s3(contents, file.filename, file.content_type or "application/octet-stream")
    except UploadError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    if url:
        return {"status": "uploaded", "location": url}
    return {"status": "stored-locally", "filename": file.filename}
