# Cryptography & Secrets

## hashlib (hashing)

```python
import hashlib

data = b"hello"
print(hashlib.md5(data).hexdigest())
print(hashlib.sha256(data).hexdigest())
print(hashlib.sha512(data).hexdigest())

def file_hash(path: str, algo: str = "sha256") -> str:
    h = hashlib.new(algo)
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()
```

## secrets (cryptographically secure)

```python
import secrets

token = secrets.token_hex(32)
urlsafe = secrets.token_urlsafe(32)
secret_bytes = secrets.token_bytes(32)

if secrets.compare_digest(input_token, expected_token):
    print("Match")
```

## Fernet (symmetric encryption)

```python
from cryptography.fernet import Fernet

key = Fernet.generate_key()
cipher = Fernet(key)

token = cipher.encrypt(b"sensitive data")
original = cipher.decrypt(token)
```

## RSA signing

```python
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa, padding

private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
public_key = private_key.public_key()

message = b"deploy v2.1 to production"
signature = private_key.sign(
    message,
    padding.PSS(mgf=padding.MGF1(hashes.SHA256()), salt_length=padding.PSS.MAX_LENGTH),
    hashes.SHA256(),
)

try:
    public_key.verify(
        signature, message,
        padding.PSS(mgf=padding.MGF1(hashes.SHA256()), salt_length=padding.PSS.MAX_LENGTH),
        hashes.SHA256(),
    )
    print("Signature valid")
except Exception:
    print("Signature invalid!")
```

## JWT tokens

```python
import jwt

payload = {
    "sub": "deploy-bot",
    "env": "production",
    "iat": datetime.now(timezone.utc),
    "exp": datetime.now(timezone.utc) + timedelta(hours=1),
}

token = jwt.encode(payload, SECRET_KEY, algorithm="HS256")

try:
    decoded = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
except jwt.ExpiredSignatureError:
    log.error("Token expired")
except jwt.InvalidTokenError:
    log.error("Invalid token")
```

## bcrypt (password hashing)

```python
import bcrypt

password = b"supersecret123"
salt = bcrypt.gensalt(rounds=12)
hashed = bcrypt.hashpw(password, salt)

if bcrypt.checkpw(password, hashed):
    print("Password matches")
```

## GPG file encryption

```python
import gnupg

gpg = gnupg.GPG(gnupghome="/path/to/gnupg/home")

with open("secret.txt", "rb") as f:
    encrypted = gpg.encrypt_file(f, recipients=["alice@example.com"])
    Path("secret.txt.gpg").write_text(str(encrypted))

with open("secret.txt.gpg", "rb") as f:
    decrypted = gpg.decrypt_file(f)
    print(decrypted.data.decode())
```

## Best practices

- Never hardcode secrets (use env vars or a secret manager)
- Use `secrets` module (not `random`) for tokens and passwords
- Use `hashlib` for checksums, `bcrypt` for passwords
- Use `cryptography` library (not raw OpenSSL bindings)
- Rotate keys regularly
- Set token expiration (`exp` claim in JWT)
- Use environment-specific keys (dev/staging/prod)
- Keep `.env` and key files out of version control
