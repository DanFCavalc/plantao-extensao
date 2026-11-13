# Auxiliar — extensão unificada

Versões prontas da extensão Auxiliar para o Chrome. A extensão só funciona em computadores
autorizados: sem licença, ela não liga e os módulos não recebem dados.

## Instalar num computador (uma vez)

1. Baixe os dois arquivos do atualizador, **Atualizar-PLANTAO.cmd** e **Atualizar-PLANTAO.ps1**,
   e guarde-os juntos, por exemplo em `C:\PLANTAO`.
2. Dê dois cliques em **Atualizar-PLANTAO.cmd**. Ele baixa a versão mais nova para
   `C:\PLANTAO\extensao`.
3. No Chrome, abra `chrome://extensions`, ligue o **Modo do desenvolvedor**, clique em
   **Carregar sem compactação** e escolha `C:\PLANTAO\extensao`.
4. Mande o código do computador ao administrador para autorizar.

Para a extensão se atualizar sozinha toda vez que alguém entrar no Windows, rode uma vez num
Prompt de Comando:
```
"C:\PLANTAO\Atualizar-PLANTAO.cmd" agendar
```

## Atualizar

Dê dois cliques em **Atualizar-PLANTAO.cmd** (ou deixe a tarefa agendada fazer isso). Depois,
reinicie o Chrome ou clique em **Recarregar** em `chrome://extensions`. O painel da extensão
mostra a versão em uso e avisa quando há uma mais nova.

**Não carregue a extensão de outra pasta.** O Chrome liga a credencial do computador à
extensão instalada; carregar de uma pasta nova obriga a autorizar o computador de novo.

## Segurança

O atualizador só instala um pacote que confira com a soma SHA-256 publicada junto e que tenha
a chave da extensão Auxiliar (ID `mmboncpcdefjgchlbhgkhckehcgaolmg`).

## Versões

Cada versão está em **Releases**, com o arquivo `plantao-extensao.zip` e a soma
`plantao-extensao.zip.sha256`.
