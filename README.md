# cloudfront-brotli-gzip

It's a project designed to demonstrate enabling Brotli and GZIP compression on CloudFront using Terraform.

## install and config

```
aws iam create-user --user-name superadmin
aws iam attach-user-policy --user-name superadmin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
aws iam create-access-key --user-name superadmin
```

```
aws configure
```

```
brew install tfenv
tfenv install 1.5.5
tfenv use 1.5.5
```

```
git clone https://github.com/danielmenezesbr/cloudfront-brotli-gzip
cd cloudfront-brotli-gzip
terraform init
terraform plan
terraform apply -auto-approve
```

# testing

```
cloudfront_url=$(terraform output cloudfront_url | tr -d '"')
curl -H "Accept-Encoding: br" -o output_file.br "https://${cloudfront_url}/index.html"
curl -H "Accept-Encoding: gzip" -o output_file.gzip "https://${cloudfront_url}/index.html"
curl -o output_file.plain "https://${cloudfront_url}/index.html"
```

```
file output_file.gzip output_file.br 
```

```
output_file.br:   data
output_file.gzip: gzip compressed data, from Unix, original size modulo 2^32 3115
```

```
brew install brotli
```

```
brotli -d -o output_file.br_uncompressed output_file.br
gzip -d -c output_file.gzip > output_file.gzip_uncompressed
```

## verifying the hash for decompressed files

### linux
```
sha256sum ./content/index.html output_file.br_uncompressed output_file.gzip_uncompressed output_file.plain
```

### macos
```
shasum -a 256 ./content/index.html output_file.br_uncompressed output_file.gzip_uncompressed output_file.plain
```

### result
```
62d1e59d757bd6ad7a4d987351af7ea06cce1222b34a35d454e801511c1145fa  ./content/index.html
62d1e59d757bd6ad7a4d987351af7ea06cce1222b34a35d454e801511c1145fa  output_file.br_uncompressed
62d1e59d757bd6ad7a4d987351af7ea06cce1222b34a35d454e801511c1145fa  output_file.gzip_uncompressed
62d1e59d757bd6ad7a4d987351af7ea06cce1222b34a35d454e801511c1145fa  output_file.plain
```

TODO:

- [ ] show results in DevTools
- [ ] show how to invalidade cache
- [ ] explain why CloudFront didn't compress style.min.js (under 1000 bytes)