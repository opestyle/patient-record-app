from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class PatientCreate(BaseModel):
    name: str
    age: int
    gender: str
    contact: str
    diagnosis: Optional[str] = None
    prescription: Optional[str] = None


class PatientRead(BaseModel):
    id: int
    name: str
    age: int
    gender: str
    contact: str
    diagnosis: Optional[str] = None
    prescription: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
