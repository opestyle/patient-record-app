import os
import uuid
from typing import Optional

import boto3

from . import config

MAX_UPLOAD_BYTES = 10 * 1024 * 1024  # 10 MB

ALLOWED_CONTENT_TYPES = {
    "application/pdf",
    "image/png",
    "image/jpeg",
    "text/plain",
}


class UploadError(ValueError):
    pass


def _build_key(filename: str) -> str:
    extension = os.path.splitext(filename)[1][:16]
    return f"uploads/{uuid.uuid4().hex}{extension}"


def upload_to_s3(file_bytes: bytes, filename: str, content_type: str) -> Optional[str]:
    if len(file_bytes) > MAX_UPLOAD_BYTES:
        raise UploadError(f"File exceeds the {MAX_UPLOAD_BYTES // (1024 * 1024)}MB upload limit")
    if content_type not in ALLOWED_CONTENT_TYPES:
        raise UploadError(f"Content type '{content_type}' is not allowed")

    bucket = config.S3_BUCKET
    if not bucket:
        if config.APP_ENV != "dev":
            raise UploadError("S3_BUCKET is not configured")
        return None

    client = boto3.client("s3", region_name=config.AWS_REGION)
    key = _build_key(filename)
    client.put_object(Bucket=bucket, Key=key, Body=file_bytes, ContentType=content_type)
    return f"https://{bucket}.s3.{config.AWS_REGION}.amazonaws.com/{key}"
