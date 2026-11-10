# Atualizar-PLANTAO.ps1 - baixa a versão mais nova da extensão PLANTÃO unificada e a coloca
# sempre na mesma pasta (padrão C:\PLANTAO\extensao). O Chrome guarda os dados da extensão
# (inclusive a credencial do computador) ligados a ela; trocar de pasta obrigaria a cadastrar o
# computador de novo, por isso a pasta é sempre a mesma e só o conteúdo é trocado.
#
# Uso (pelo "Atualizar-PLANTAO.cmd", com dois cliques):
#   Atualizar-PLANTAO.ps1                 atualiza agora e mostra o resultado
#   Atualizar-PLANTAO.ps1 -Agendar        também cria a tarefa do Windows que atualiza ao entrar no usuário
#   Atualizar-PLANTAO.ps1 -Silencioso     sem janelas (usado pela tarefa); o resultado vai para atualizar.log
#   Atualizar-PLANTAO.ps1 -Zip <arquivo>  usa um zip local em vez de baixar (teste)
#
# Segurança: o zip e o próprio atualizador só são aceitos com a assinatura (.sig) feita pela chave
# privada de quem publica, conferida com a chave pública abaixo ($ChaveAssinatura). Quem conseguir
# publicar no GitHub sem essa chave não consegue instalar nada. Também confere a soma SHA-256, a
# chave do manifest (que fixa o ID mmboncpcdefjgchlbhgkhckehcgaolmg) e não volta para versão mais velha.
param(
  [string]$Pasta = 'C:\PLANTAO\extensao',
  [switch]$Agendar,
  [switch]$Silencioso,
  [string]$Zip = ''
)
$ErrorActionPreference = 'Stop'
$Repositorio = 'DanFCavalc/plantao-extensao'
$ChavePublica = 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAkKZnHomYn3JJWCJk/O+K8pr9Xu0NI/XmU1BE2s1bi+mJY2tf1mF1G/ycmI9ys6178taniRyNLsNzW74nPXeEs9ZR7ul+npg4c19eVNoP2SORtoRZ9IWH8ZduH7tasLun7XA0HMJ+KBp81nIPYxFKVwjAhKlyT4rSyMdWackPjFcvWhDFmsxLry5W8f2wJwHljshDee5Zym4CJxaFrsd4kzOop1llsIZvGbPufbqwcu0j43985mRVLFtKlJ6pH9lvCB3BMfVAF3CY7RCHjtgQXLukHUlC86bI2mxHRf3iLWbrgrkzgWKq4uego3uTpvXDE5W98mLwRvrW7lfXHNB0ZwIDAQAB'
$ChaveAssinatura = '<RSAKeyValue><Modulus>xM+dW30Pt/h/LpjmrSS4DTNKKHKjkoX6we2AzVVUlHUDNlmygfzV3Fza9Aq0F2/wCa7BEXq0FsxdWPrJ40hPxIzLUY1AHt3y6akdAiRDZMY7kN+KSpuVTYTJgOn64s64Pt2XGWT4NXkpjD4g1e+pwh/jMxgGLd3p3/4zu6bRhfsqMAxzqBWeYIN52Sl/aLq2NI5f7Y3Owii3LgT9Z/zzTSKbtkwkU8qdbBPvcKKjWdvKLhXU8wVm1E9VNzTF4fQ/MID7z5TGx174VCrdk8ZOKyJd2kTrBZ5+4ZpCAZUL2WlK9JIZncJH8QA/M9uPjWk51Ju9bfmOdE33krcU+ScJ+fSYdb4FdhZ114+cFFaZmsbXPdjSBM4I9WnMSO9vnk5T/C4+xZyH1b2PKjYV3AgpLcfjMQ8+wJCrnrL/Ny2L/gq0360Aj/hfyuAl/2Wyy260tocu8Po6/vyo5JWf12oexsxFXrHG+OtIEbCnM0aPUEIjctQgsTaQBAatZNyzf/fL</Modulus><Exponent>AQAB</Exponent></RSAKeyValue>'
$Base = "https://github.com/$Repositorio/releases/latest/download"
$Raiz = Split-Path -Parent $Pasta
$Log = Join-Path $Raiz 'atualizar.log'

function Avisar([string]$Texto, [bool]$Erro = $false) {
  $linha = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $Texto"
  if (-not (Test-Path $Raiz)) { New-Item -ItemType Directory -Path $Raiz -Force | Out-Null }
  Add-Content -Path $Log -Value $linha -Encoding UTF8
  if ($Silencioso) { return }
  if ($Erro) { Write-Host $Texto -ForegroundColor Red } else { Write-Host $Texto -ForegroundColor Green }
}

# Assinatura RSA/SHA-256 (base64 no arquivo .sig) do arquivo, com a chave pública de assinatura.
function AssinaturaValida([string]$Arquivo, [string]$ArquivoSig) {
  if (-not (Test-Path $ArquivoSig)) { return $false }
  try {
    $rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider
    $rsa.PersistKeyInCsp = $false
    $rsa.FromXmlString($ChaveAssinatura)
    $sig = [Convert]::FromBase64String((Get-Content -Path $ArquivoSig -Raw).Trim())
    return $rsa.VerifyData([IO.File]::ReadAllBytes($Arquivo), [Security.Cryptography.CryptoConfig]::MapNameToOID('SHA256'), $sig)
  } catch { return $false }
}

# Proteção: só troca o conteúdo de uma pasta chamada "extensao", nunca de uma raiz de disco.
$Pasta = [IO.Path]::GetFullPath($Pasta)
if ((Split-Path -Leaf $Pasta) -ne 'extensao' -or $Pasta.Length -lt 8) { throw "Pasta inválida: $Pasta (precisa terminar em \extensao)." }

$tmp = Join-Path ([IO.Path]::GetTempPath()) ('plantao-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $arquivo = Join-Path $tmp 'plantao-extensao.zip'
  if ($Zip) {
    Copy-Item -Path $Zip -Destination $arquivo
    if (Test-Path "$Zip.sha256") { Copy-Item -Path "$Zip.sha256" -Destination "$arquivo.sha256" }
    if (Test-Path "$Zip.sig") { Copy-Item -Path "$Zip.sig" -Destination "$arquivo.sig" }
  } else {
    Invoke-WebRequest -UseBasicParsing -Uri "$Base/plantao-extensao.zip" -OutFile $arquivo
    Invoke-WebRequest -UseBasicParsing -Uri "$Base/plantao-extensao.zip.sha256" -OutFile "$arquivo.sha256"
    Invoke-WebRequest -UseBasicParsing -Uri "$Base/plantao-extensao.zip.sig" -OutFile "$arquivo.sig"
  }

  # 0. Assinado por quem publica?
  if (-not (AssinaturaValida $arquivo "$arquivo.sig")) { throw 'O pacote não tem assinatura válida de quem publica o PLANTÃO. Nada foi alterado.' }

  # 1. A soma confere?
  $esperado = ((Get-Content -Path "$arquivo.sha256" -Raw) -split '\s+')[0].Trim().ToLower()
  $obtido = (Get-FileHash -Path $arquivo -Algorithm SHA256).Hash.ToLower()
  if ($esperado -ne $obtido) { throw 'O arquivo baixado não confere com a soma publicada. Nada foi alterado.' }

  # 2. É a extensão PLANTÃO (mesma chave, mesmo ID)?
  $novo = Join-Path $tmp 'novo'
  Expand-Archive -Path $arquivo -DestinationPath $novo
  $manifest = Get-Content -Path (Join-Path $novo 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($manifest.key -ne $ChavePublica) { throw 'O pacote não é a extensão PLANTÃO (chave diferente). Nada foi alterado.' }
  $versaoNova = $manifest.version

  $versaoAtual = ''
  $manifestAtual = Join-Path $Pasta 'manifest.json'
  if (Test-Path $manifestAtual) { try { $versaoAtual = (Get-Content -Path $manifestAtual -Raw -Encoding UTF8 | ConvertFrom-Json).version } catch {} }
  # Não volta para uma versão mais velha (uma versão antiga, mesmo assinada, republicada como a mais nova).
  if ($versaoAtual -and ([version]$versaoNova) -lt ([version]$versaoAtual)) { throw "O pacote é a versão $versaoNova, mais velha que a instalada ($versaoAtual). Nada foi alterado." }

  # Mesma versão: confere arquivo por arquivo (uma queda de energia pode deixar arquivos
  # corrompidos ou vazios). Algum diferente ou faltando: reinstala a mesma versão.
  $corrompidos = @()
  if ($versaoAtual -eq $versaoNova) {
    $baseNovo = (Resolve-Path $novo).Path.TrimEnd('') + ''
    foreach ($f in Get-ChildItem -Path $novo -Recurse -File) {
      $rel = $f.FullName.Substring($baseNovo.Length).TrimStart([char]92)
      $instalado = Join-Path $Pasta $rel
      if (-not (Test-Path $instalado) -or (Get-FileHash -Path $instalado -Algorithm SHA256).Hash -ne (Get-FileHash -Path $f.FullName -Algorithm SHA256).Hash) { $corrompidos += $rel }
    }
  }

  if ($versaoAtual -eq $versaoNova -and $corrompidos.Count -eq 0) {
    Avisar "PLANTÃO já está na versão $versaoNova (em $Pasta)."
  } else {
    # 3. Troca o conteúdo, sempre na mesma pasta.
    if (-not (Test-Path $Pasta)) { New-Item -ItemType Directory -Path $Pasta -Force | Out-Null }
    Get-ChildItem -Path $Pasta -Force | Remove-Item -Recurse -Force
    Copy-Item -Path (Join-Path $novo '*') -Destination $Pasta -Recurse -Force
    if ($corrompidos.Count -gt 0) {
      Avisar "PLANTÃO $versaoNova reparado ($($corrompidos.Count) arquivo(s) corrompido(s) ou faltando: $(($corrompidos | Select-Object -First 5) -join ', ')). Reinicie o Chrome (ou clique em Recarregar em chrome://extensions)."
    } elseif ($versaoAtual) {
      Avisar "PLANTÃO atualizado de $versaoAtual para $versaoNova. Reinicie o Chrome (ou clique em Recarregar em chrome://extensions)."
    } else {
      Avisar "PLANTÃO $versaoNova instalado em $Pasta. No Chrome: chrome://extensions, ligue o Modo do desenvolvedor, Carregar sem compactação e escolha essa pasta."
    }
  }

  # 3b. Este script também se atualiza: a cópia em C:\PLANTAO (a da tarefa agendada) recebe a versão
  # publicada junto com a extensão, só com assinatura válida.
  if (-not $Zip) {
    try {
      $copiaScript = Join-Path $Raiz 'Atualizar-PLANTAO.ps1'
      $scriptNovo = Join-Path $tmp 'Atualizar-PLANTAO.ps1'
      Invoke-WebRequest -UseBasicParsing -Uri "$Base/Atualizar-PLANTAO.ps1" -OutFile $scriptNovo
      Invoke-WebRequest -UseBasicParsing -Uri "$Base/Atualizar-PLANTAO.ps1.sig" -OutFile "$scriptNovo.sig"
      if ((AssinaturaValida $scriptNovo "$scriptNovo.sig") -and (Test-Path $copiaScript) -and
          (Get-FileHash $scriptNovo).Hash -ne (Get-FileHash $copiaScript).Hash) {
        Copy-Item -Path $scriptNovo -Destination $copiaScript -Force
      }
    } catch {}
  }

  # 4. Tarefa do Windows: atualiza sozinho ao entrar no usuário.
  if ($Agendar) {
    $copia = Join-Path $Raiz 'Atualizar-PLANTAO.ps1'
    if ($PSCommandPath -ne $copia) { Copy-Item -Path $PSCommandPath -Destination $copia -Force }
    $acao = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$copia`" -Pasta `"$Pasta`" -Silencioso"
    $gatilho = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
    Register-ScheduledTask -TaskName 'PLANTAO - atualizar' -Action $acao -Trigger $gatilho -Description 'Atualiza a extensão PLANTÃO unificada ao entrar no Windows.' -Force | Out-Null
    Avisar "Tarefa 'PLANTAO - atualizar' criada: a extensão se atualiza ao entrar no Windows."
  }
} catch {
  Avisar "Falha ao atualizar o PLANTÃO: $($_.Exception.Message)" $true
  if (-not $Silencioso) { exit 1 }
} finally {
  Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
