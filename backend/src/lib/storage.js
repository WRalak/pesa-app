import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { config } from '../config/env.js';
import { randomToken } from './crypto.js';

/**
 * S3-compatible object storage (AWS S3 in production, MinIO locally).
 * Clients upload directly with short-lived presigned URLs; the API never
 * proxies file bytes. Buckets are private with SSE-KMS encryption.
 */
let client;
function s3() {
  client ??= new S3Client({
    region: config.S3_REGION,
    endpoint: config.S3_ENDPOINT,
    forcePathStyle: Boolean(config.S3_ENDPOINT),
  });
  return client;
}

const ALLOWED = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp', 'application/pdf': 'pdf' };

export async function presignUpload({ prefix, contentType, maxBytes = 5 * 1024 * 1024 }) {
  const ext = ALLOWED[contentType];
  if (!ext) throw new Error('Unsupported content type');
  const key = `${prefix}/${randomToken(16)}.${ext}`;
  const url = await getSignedUrl(s3(), new PutObjectCommand({
    Bucket: config.S3_BUCKET, Key: key, ContentType: contentType, ServerSideEncryption: config.S3_ENDPOINT ? undefined : 'aws:kms',
  }), { expiresIn: 300 });
  return { key, url, method: 'PUT', headers: { 'Content-Type': contentType }, maxBytes, expiresIn: 300 };
}

export async function presignDownload(key, expiresIn = 300) {
  if (!key) return null;
  return getSignedUrl(s3(), new GetObjectCommand({ Bucket: config.S3_BUCKET, Key: key }), { expiresIn });
}

export const ALLOWED_UPLOAD_TYPES = Object.keys(ALLOWED);
