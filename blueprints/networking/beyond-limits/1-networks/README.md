# Stage 1

## Generate Stage 2 TF Vars

```bash
OUT=$(terraform output stage2-input) && echo "network-config = $OUT" > ../2-connecting/terraform.tfvars
```
