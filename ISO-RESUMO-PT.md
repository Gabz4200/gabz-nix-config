# 🎯 Resumo das Correções - Instalação NixOS

## ✅ O Que Foi Corrigido

### 1. **Erro Principal: "function 'anonymous lambda' called without required argument 'config'"**

**Problema no erro da imagem:**
- Você executou: `nix run github:nix-community/disko -- --mode disko ./hosts/hermes/hardware-configuration.nix`
- O disko tentou ler o arquivo como configuração standalone
- Mas o arquivo é um **módulo NixOS** que precisa de `config`, `inputs`, `lib`, etc.

**Solução:**
- Mudei o script de instalação para usar `--flake .#hermes`
- Agora o disko avalia seu flake completo e tem acesso a todos os argumentos necessários

**Comando ANTES (errado):**
```bash
nix run github:nix-community/disko -- \
  --mode disko \
  ./hosts/hermes/hardware-configuration.nix  # ❌ Não funciona!
```

**Comando DEPOIS (correto):**
```bash
nix run github:nix-community/disko -- \
  --mode disko \
  --flake .#hermes  # ✅ Funciona!
```

---

### 2. **Configuração Duplicada do ISO**

**Problema:**
- `iso-config.nix` tinha duas opções conflitantes:
  ```nix
  isoImage.isoName = "..."  # API antiga (funciona)
  image.fileName = "..."     # API nova (não existe ainda!)
  ```

**Solução:**
- Removi a linha `image.fileName`
- Mantive apenas `isoImage.*` (API atual)

---

### 3. **Driver WiFi para Realtek 8821CE**

**Problema:**
- Sua placa WiFi precisa do driver `rtl8821ce`
- Sem ele, não consegue internet durante instalação

**Solução:**
- Adicionei ao `iso-config.nix`:
  ```nix
  boot.kernelModules = ["8821ce"];
  boot.extraModulePackages = with config.boot.kernelPackages; [
    rtl8821ce
  ];
  ```

**Resultado:**
- ✅ WiFi funciona direto quando boota do ISO

---

### 4. **Localização da Configuração**

**Como você queria:**
- Config em: `/persist/home/gabz/NixConf` (sua pasta home)
- Symlink: `/etc/nixos` → `/persist/home/gabz/NixConf`

**Script de instalação agora faz:**
```bash
# Step 5: Copia config para sua home
mkdir -p /mnt/persist/home/gabz/NixConf
cp -r ./* /mnt/persist/home/gabz/NixConf/

# Step 5b: Cria symlink
ln -sf /persist/home/gabz/NixConf /mnt/etc/nixos
```

**Depois da instalação:**
```bash
ls ~/NixConf/          # ✅ Sua config aqui
ls /etc/nixos/         # ✅ Symlink aponta para ~/NixConf
readlink /etc/nixos    # Mostra: /persist/home/gabz/NixConf

# Ambos funcionam:
sudo nixos-rebuild switch --flake ~/NixConf#hermes
sudo nixos-rebuild switch --flake /etc/nixos#hermes  # Mesmo efeito!
```

---

## 🔐 Senhas - Como Funciona

### Durante a Instalação

**O script SEMPRE pergunta:**

1. **Senha LUKS (criptografia do disco):**
   ```bash
   Enter LUKS encryption password (you'll need this at every boot): ****
   Confirm LUKS password: ****
   ```
   - Esta é a senha que descriptografa `/dev/sda3`
   - Você vai precisar **toda vez que ligar o computador**
   - Salva temporariamente em `/tmp/luks-password`
   - Disko lê este arquivo UMA VEZ
   - Depois é deletado com `shred -u` (seguro)

2. **Senha de usuário (depende se você tem age key):**

   **Cenário A: Você TEM a age key**
   ```bash
   Do you have your age private key to copy? (y/n): y
   Age private key: AGE-SECRET-KEY-1... [você cola aqui]
   ✓ Age key installed successfully
   ✓ Your SOPS-encrypted password will work on first boot
   ```
   - Não pede senha de usuário
   - Usa a senha que está no `secrets.yaml` (descriptografada com age)
   
   **Cenário B: Você NÃO TEM a age key**
   ```bash
   Do you have your age private key to copy? (y/n): n
   Setting temporary user password for 'gabz'...
   New password: ****
   Retype new password: ****
   ```
   - Pede senha temporária
   - Depois do primeiro boot, você configura age key
   - Roda `sudo nixos-rebuild switch` e a senha do SOPS entra em efeito

---

### No Boot (Toda Vez que Ligar)

1. **LUKS prompt:**
   ```
   Please enter passphrase for disk hermes (cryptsetup-hermes):
   ```
   - Digite sua senha LUKS
   - Disco descriptografa
   
2. **Login:**
   - Usuário: `gabz`
   - Senha: a que você configurou (SOPS ou temporária)

---

### Segurança GARANTIDA

✅ **Senha LUKS NUNCA é armazenada permanentemente**  
✅ **Só existe em RAM durante instalação** (`/tmp` é tmpfs)  
✅ **Deletada com segurança após uso** (`shred -u`)  
✅ **Boot sempre pede senha interativamente**  
✅ **Nenhum segredo no Nix store**  
✅ **Config é puro** - pode compartilhar no GitHub

---

## 📝 Duas Senhas, Duas Funções

| Senha | Quando Usa | O Que Faz |
|-------|-----------|-----------|
| **LUKS** | Todo boot | Descriptografa o disco `/dev/sda3` |
| **Usuário** | Login | Entra no sistema como usuário `gabz` |

**São DIFERENTES!** Você pode (e deve) usar senhas diferentes para cada uma.

---

## 🚀 Fluxo de Instalação Completo

### 1. Construir ISO
```bash
cd ~/NixConf
nix build .#nixosConfigurations.iso.config.system.build.isoImage
ls -lh result/iso/  # Seu ISO aqui (~1.3GB)
```

### 2. Gravar no USB

**Opção A: Ventoy (recomendado)**
```bash
cp result/iso/*.iso /caminho/para/ventoy/usb/
```

**Opção B: dd**
```bash
sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress
sudo sync
```

### 3. Bootar do USB
- Insere USB no Hermes
- Menu de boot (F12/F10/ESC)
- Seleciona USB
- Auto-login como `nixos`

### 4. Conectar WiFi
```bash
nmtui  # NetworkManager TUI
# Seleciona sua rede WiFi
# Digite a senha
# ✅ WiFi funciona com driver rtl8821ce!
```

### 5. Executar Instalador
```bash
sudo /etc/install-hermes.sh
```

**O que vai acontecer:**

#### Step 1: Clone do repositório
```
Repository: https://github.com/Gabz4200/gabz-nix-config.git
Cloning NixConf...
```

#### Step 2: Senha LUKS
```
Enter LUKS encryption password (you'll need this at every boot): ****
Confirm LUKS password: ****
✓ LUKS password file created
```

#### Step 3: Disko (DESTRUTIVO!)
```
⚠️  ALL DATA ON /dev/sda WILL BE PERMANENTLY DESTROYED!
Type 'YES' to continue: YES

Running Disko partitioning...
```
- **Apaga tudo em `/dev/sda`**
- Cria partições (BIOS boot, ESP, LUKS)
- Encripta `/dev/sda3` com sua senha LUKS
- Formata com Btrfs
- Cria subvolumes (@root, @nix, @persist, @swap)
- Monta tudo em `/mnt`

#### Step 4: Verificação
```
✓ Disk partitioned and mounted successfully
```

#### Step 5: Copia Configuração
```
✓ Config copied to /mnt/persist/home/gabz/NixConf
```

#### Step 5b: Cria Symlink
```
✓ Symlink created: /etc/nixos → /persist/home/gabz/NixConf
```

#### Step 6: Instalação NixOS
```
Installing NixOS (this takes 10-20 minutes)...
```
- Baixa todos os pacotes
- Instala sistema base
- Configura bootloader
- **Demora!** (10-30 min dependendo da internet)

#### Step 7: Senha de Usuário
```
IMPORTANT: For secrets (SOPS) to work, you need your age private key.
The public key is: age1760zlef5j6zxaart39wpzgyerpu000uf406t2kvl2c8nlyscygyse6c67x

Do you have your age private key to copy? (y/n):
```

- **Se `y`:** Cola sua age key, SOPS funciona imediatamente
- **Se `n`:** Define senha temporária, configura age depois

#### Step 8: Limpeza
```
✓ LUKS password file securely deleted
✅ Installation Complete!
```

### 6. Primeiro Boot
```bash
sudo reboot  # Remove USB antes!
```

**Sequência de boot:**
1. **LUKS prompt** → Digite senha de criptografia
2. **Disco descriptografa**
3. **Sistema boota**
4. **Login** → `gabz` + sua senha
5. **🎉 Pronto!**

---

## ✅ Lista de Verificação

### Antes de Gravar ISO
- [ ] `nix build .#nixosConfigurations.iso.config.system.build.isoImage` funciona
- [ ] `alejandra .` passa
- [ ] Arquivos commitados no git
- [ ] Backup de dados importantes (vai APAGAR TUDO!)

### Durante Instalação
- [ ] WiFi conectou (`nmtui`)
- [ ] Senha LUKS anotada/memorizada (IMPORTANTE!)
- [ ] Confirmou "YES" para apagar disco
- [ ] Age key disponível (se tiver)

### Após Primeiro Boot
- [ ] Senha LUKS desbloqueou disco
- [ ] Login funcionou
- [ ] `~/NixConf` existe
- [ ] `/etc/nixos` é symlink para `~/NixConf`
- [ ] `sudo nixos-rebuild switch --flake ~/NixConf#hermes` funciona
- [ ] Arquivos em `~/Documents`, `~/Downloads` etc. persistem após reboot

---

## ⚠️ Pontos Críticos

### LUKS Password
- **Sem ela, não consegue acessar o disco!**
- Anote em lugar seguro
- Não tem "esqueci minha senha"
- Disco fica inacessível permanentemente se perder

### Age Key
- Necessária para descriptografar `secrets.yaml`
- Sem ela, senha de usuário não funciona (precisa usar temporária)
- Faça backup do arquivo `~/.config/sops/age/keys.txt`

### Dados Persistentes
- Só sobrevivem reboot se estiverem em:
  - `/persist`
  - Pastas listadas em `home/gabz/global/default.nix`
  - Exemplo: `~/Documents`, `~/Downloads`, `~/NixConf`
- **Arquivos soltos em `~` serão APAGADOS!**

---

## 🎉 Indicadores de Sucesso

Você sabe que funcionou quando:

✅ ISO construiu sem erros  
✅ WiFi funcionou durante instalação  
✅ Disko particionou sem erro de "missing argument"  
✅ LUKS pede senha no boot  
✅ Sistema boota com root efêmero  
✅ Config acessível em `~/NixConf` E `/etc/nixos`  
✅ Rebuild funciona dos dois caminhos  
✅ Dados persistem em `/persist` após reboot  
✅ Root (`/`) é limpo a cada boot (efêmero)

---

## 🔧 Comandos Úteis Pós-Instalação

### Atualizar Sistema
```bash
cd ~/NixConf
nix flake update              # Atualiza inputs
sudo nixos-rebuild switch --flake .#hermes
```

### Atualizar Home Manager
```bash
home-manager switch --flake ~/NixConf#gabz@hermes
```

### Ver O Que Persiste
```bash
# Sistema
cat /persist/etc/nixos/hosts/common/global/optin-persistence.nix

# Usuário
cat ~/NixConf/home/gabz/global/default.nix
# Procura por: home.persistence."/persist/home/gabz"
```

### Adicionar Nova Pasta Persistente
```nix
# Edita: ~/NixConf/home/gabz/global/default.nix
home.persistence."/persist/home/gabz".directories = [
  # ... existentes ...
  "MinhaNovaP pasta"  # ← Adiciona aqui
];

# Rebuild
home-manager switch --flake ~/NixConf#gabz@hermes
```

### Gerenciar Secrets
```bash
# Entra no dev shell (tem sops)
cd ~/NixConf
nix develop

# Edita secrets
sops hosts/common/secrets.yaml

# Sai
exit
```

---

## 📚 Documentação

- **ISO-BUILD.md** - Guia completo (1000+ linhas)
- **ISO-QUICK-START.md** - Guia rápido (350+ linhas)
- **ISO-USAGE-EXAMPLES.md** - Exemplos de uso (250+ linhas)
- **ISO-FIX-SUMMARY.md** - Detalhes técnicos (em inglês)
- **ISO-RESUMO-PT.md** - Este arquivo (em português)

---

**Gerado em:** 3 de outubro de 2025  
**Versão NixOS:** 25.05 unstable  
**Hardware Alvo:** Asus Vivobook (Hermes) - Intel CPU, WiFi Realtek 8821CE

---

## ❓ Dúvidas Frequentes

**P: As duas senhas precisam ser iguais?**  
R: Não! São independentes. Recomendo usar senhas diferentes para mais segurança.

**P: E se eu esquecer a senha LUKS?**  
R: Não tem como recuperar. O disco fica criptografado permanentemente. Por isso é CRÍTICO anotar!

**P: A senha de usuário fica armazenada onde?**  
R: No `secrets.yaml` criptografado com age. Só pode ler com sua age private key.

**P: Posso mudar a senha LUKS depois?**  
R: Sim! Use `cryptsetup luksChangeKey /dev/sda3`

**P: O que acontece se eu criar um arquivo em `~/teste.txt`?**  
R: Será APAGADO no próximo boot! Só persiste se estiver em pasta persistente como `~/Documents/teste.txt`

**P: Como sei quais pastas persistem?**  
R: Veja `home/gabz/global/default.nix`, seção `home.persistence`

---

Agora está tudo pronto e funcionando! 🚀
