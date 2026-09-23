# software-avanzado-gitops

Repositorio GitOps de la plataforma PrintHub (Software Avanzado, Práctica 9).
Es la **única fuente de verdad** del clúster `sa-p9`: ArgoCD lo lee y aplica los
cambios; nadie despliega con `kubectl` ni `helm upgrade`.

El código fuente, el Terraform y el pipeline están en
[Practicas-SA-B-201901444](https://github.com/GeoNufio1404/Practicas-SA-B-201901444) (carpeta `/P9`).

## Estructura

```
apps/                       Applications hijas del app-of-apps (raíz: root-sa-p9, ns argocd)
  argo-rollouts.yaml        wave 0  Argo Rollouts
  kyverno.yaml              wave 0  Kyverno
  external-secrets.yaml     wave 0  External Secrets Operator (Workload Identity)
  velero.yaml               wave 0  Velero + schedule sa-p9-hourly → gs://sa-p9-velero-201901444
  platform-config.yaml      wave 1  carpeta config/
  velero-restore.yaml       wave 1  carpeta restore/ (restaura MySQL antes de la wave 2)
  sa-platform.yaml          wave 2  chart charts/sa-platform en el namespace sa-p9
config/
  cluster-secret-store.yaml ClusterSecretStore → GCP Secret Manager
  kyverno-policies.yaml     disallow-latest-tag, require-resource-limits, require-run-as-non-root
restore/
  restore-mysql.yaml        Job que, si no existe el volumen de MySQL, lo restaura desde el
                            último respaldo de sa-p9-hourly y bloquea la wave 2 hasta terminar
charts/sa-platform/         chart padre + un subchart por microservicio
  values.yaml               valores base
  values-dev.yaml / values-prod.yaml / values-gke.yaml   valores por ambiente (ArgoCD usa values-gke)
```

## Reglas

- El pipeline solo modifica las etiquetas `tag:` de `charts/sa-platform/values-gke.yaml`
  mediante un Pull Request.
- No se versionan secretos: los `ExternalSecret` solo referencian nombres de Secret Manager.
- Namespace, ResourceQuota, LimitRange, RBAC, ArgoCD y la aplicación raíz los crea Terraform.
