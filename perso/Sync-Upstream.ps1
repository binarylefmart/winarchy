# Sync-Upstream.ps1 — récupère les mises à jour du projet d'origine (remote `upstream`)
# en gardant les réglages et fix perso, puis pousse le tout sur ton fork (`origin`).
# Lancé par setup-winarchy.ps1 ; utilisable seul.
#
# Remplace `winarchy update --self`, qui ne sait faire qu'un fast-forward depuis origin et
# échoue dès qu'il y a des commits locaux.
#
#   pwsh -File C:\winarchy\perso\Sync-Upstream.ps1                  # merge + migration + push
#   pwsh -File C:\winarchy\perso\Sync-Upstream.ps1 -Check           # dit seulement s'il y a du nouveau
#   pwsh -File C:\winarchy\perso\Sync-Upstream.ps1 -SauverSeulement # commit des réglages + push

param([switch]$Check, [switch]$SauverSeulement)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$branch = 'release'
function Invoke-Git { & git -C $root @args; if ($LASTEXITCODE -ne 0) { throw "git $($args -join ' ') a échoué" } }

# Push via « gh auth git-credential » : hors d'une session Claude, on prend le profil gh perso
# (celui où le compte du fork est connecté).
if (-not $env:GH_CONFIG_DIR) {
    $ghPerso = Join-Path $HOME '.config\gh-perso'
    if (Test-Path (Join-Path $ghPerso 'hosts.yml')) { $env:GH_CONFIG_DIR = $ghPerso }
}

# Modèles que setup-winarchy.ps1 repatche à chaque lancement : en cas de conflit avec le
# projet d'origine, on prend sa version et le script réapplique les réglages par-dessus.
$repatches = 'templates/komorebi.json.tpl', 'templates/yasb-config.yaml.tpl', 'templates/yasb-styles.css.tpl', 'games.toml',
             'vendor/asc/applications.json', 'module/Winarchy/Private/Util.ps1'

# Remotes attendus : origin = ton fork, upstream = projet d'origine.
if (-not (& git -C $root remote | Where-Object { $_ -eq 'upstream' })) {
    Invoke-Git remote add upstream 'https://github.com/guidonaselli/winarchy.git'
}

# 1. Réglages perso modifiés depuis le dernier commit (layout save, rules.toml…) : on les commit.
$perso = @('config/ahk/user.ahk', 'config/windows.toml', 'config/komorebi/rules.toml',
           'config/jetbrains/winarchy.icls') + $repatches
$dirty = @(& git -C $root status --porcelain --untracked-files=no | ForEach-Object { $_.Substring(3) })
$other = $dirty | Where-Object { $_ -notin $perso -and $_ -notlike 'perso/*' }
if ($other) {
    Write-Host "Fichiers versionnés modifiés hors réglages perso, à committer d'abord :" -ForegroundColor Red
    $other | ForEach-Object { "  $_" }
    exit 1
}
if ($dirty -and -not $Check) {
    Invoke-Git add -- @dirty
    Invoke-Git commit -q -m "perso: maj réglages $(Get-Date -Format yyyy-MM-dd)"
    Write-Host "Réglages perso committés : $($dirty -join ', ')"
}
if ($SauverSeulement) { Invoke-Git push -q origin $branch; exit 0 }

# 2. Nouveautés en amont ?
Invoke-Git fetch -q upstream $branch
$new = @(& git -C $root log --oneline "HEAD..upstream/$branch")
if (-not $new) { Write-Host 'Déjà à jour avec le projet d''origine.' -ForegroundColor Green; if (-not $Check) { Invoke-Git push -q origin $branch }; exit 0 }
Write-Host "$($new.Count) commit(s) en amont :"; $new | Select-Object -First 15 | ForEach-Object { "  $_" }
if ($Check) { exit 0 }

# 3. Merge. En cas de conflit on annule tout : rien n'est cassé, à résoudre à la main.
$before = (& git -C $root rev-parse HEAD)
& git -C $root merge --no-edit "upstream/$branch"
if ($LASTEXITCODE -ne 0) {
    $conflicts = @(& git -C $root diff --name-only --diff-filter=U)
    $autres = @($conflicts | Where-Object { $_ -notin $repatches })
    if ($conflicts -and -not $autres) {
        # Seulement des modèles repatchés : version d'origine, setup-winarchy.ps1 repatche ensuite.
        Invoke-Git checkout --theirs -- @conflicts
        Invoke-Git add -- @conflicts
        Invoke-Git commit -q --no-edit
        Write-Host "Modèles repris du projet d'origine (à repatcher par setup-winarchy.ps1) : $($conflicts -join ', ')" -ForegroundColor Yellow
    }
    else {
        if ($conflicts) { & git -C $root merge --abort }
        Write-Host 'Merge impossible, rien n''a changé :' -ForegroundColor Red
        $autres | ForEach-Object { "  conflit : $_" }
        Write-Host "Résoudre à la main : git -C $root merge upstream/$branch"
        exit 1
    }
}

# 4. Migration idempotente, comme le fait `winarchy update --self`.
& pwsh -NoProfile -File (Join-Path $root 'install.ps1') -SkipPackages
if ($LASTEXITCODE -ne 0) {
    Write-Host "Migration en échec. Retour arrière : git -C $root reset --hard $before ; puis relancer install.ps1" -ForegroundColor Red
    exit 1
}

Invoke-Git push -q origin $branch
Remove-Item (Join-Path $root 'state\update-available.flag') -Force -ErrorAction SilentlyContinue
Write-Host "Winarchy à jour et poussé sur ton fork. Retour arrière possible : git -C $root reset --hard $before" -ForegroundColor Green
