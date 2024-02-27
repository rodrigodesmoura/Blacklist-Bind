#!/bin/bash
#Autor Rodrigo Moura - Tier Solutions
echo "........................................................................................................"
echo "........................... Criação de Zona de Blacklist no Bind9 ......................................"
echo "--------------------------------------------------------------------------------------------------------"
echo ".......................... Criado por Tier Solutions - RODRIGO MOURA ..................................."
echo "........................................................................................................"
echo "........................... Obs.: É necessário ter o Bind installado. .................................."

# Verificando a existência do diretório
if [ -d "/var/cache/bind/blacklist/" ]; then
    echo "O diretório /var/cache/bind/blacklist/ já existe."
    exit 1
fi

# Criando o diretório e o arquivo necessários
mkdir -p /var/cache/bind/blacklist/
touch /var/cache/bind/blacklist/db.blacklist.zone

# Alterando a propriedade do diretório
chown bind. /var/cache/bind/blacklist -R

# Adicionando ao arquivo /etc/bind/named.conf.local
echo 'zone "blacklist.zone" {
    type master;
    file "/var/cache/bind/blacklist/db.blacklist.zone";
};' | tee -a /etc/bind/named.conf.local

# Adicionando ao arquivo /etc/bind/named.conf.options
sed -i '$i response-policy {\n    zone "blacklist.zone" policy CNAME localhost;\n};' /etc/bind/named.conf.options

# Informando que a zona de blacklist foi criada
echo "A zona de blacklist foi criada."

# Adicionando a linha ao arquivo /etc/crontab
sed -i '$i 30 0    * * *   root    /home/att-blacklist' /etc/crontab

# Reiniciando o cron
service cron restart

# Criando o arquivo
touch /home/att-blacklist

# Adicionando permissões ao arquivo
chmod 755 /home/att-blacklist

# Adicionando o script ao arquivo
cat << 'EOF' > /home/att-blacklist
#!/bin/bash
#Autor Rodrigo Moura - Tier Solutions

# Verifica se o wget está instalado
if ! command -v wget &> /dev/null
then
    echo "wget não encontrado, instalando..."
    apt-get install wget -y > /dev/null 2>&1
    echo "wget instalado com sucesso."
else
    echo "wget já está instalado."
fi

# Baixa o arquivo da URL fornecida  // Contribuição --no-check-certificate por Romerito Brandão //
wget --no-check-certificate http://ENDEREÇO_SERVIDOR_WEB/db.blacklist.zone -O db.blacklist.zone.tmp
# Compara o arquivo baixado com o arquivo local
diff db.blacklist.zone.tmp /var/cache/bind/blacklist/db.blacklist.zone > /dev/null
# Se os arquivos forem diferentes, substitui o arquivo local pelo baixado
if [ $? -ne 0 ]; then
  mv db.blacklist.zone.tmp /var/cache/bind/blacklist/db.blacklist.zone
  echo "O arquivo foi atualizado com sucesso."
  # Reinicia o bind9
  service bind9 restart
  echo "O bind9 foi reiniciado com sucesso."
# Se os arquivos forem iguais, exclui o arquivo baixado
else
  rm db.blacklist.zone.tmp
  echo "Não houve atualizações."
fi
EOF

#Sicronizar com a Base
sh /home/att-blacklist
