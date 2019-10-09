#!/bin/bash

set -x

# Скрипт переноса .xml.pgp файлов на другой сервер
# Разработал Антон Захаров hello@antonzakharov.ru

################
# КОНФИГУРАЦИЯ #
################

# Путь где находятся файлы
PATH_SOURCE=/mnt/OWS/OWS_WORK/data/card_prd/EXPORT/

# куда складывать архивы
PATH_DESTINATION=REMOTEUSER@10.0.0.1:

DO_DELETE=1

FILE_EXTENSION=.xml.pgp

########################
# НАЧАЛО АРХИВИРОВАНИЯ #
########################

# Инициализируем переменные
BDATEFORMAT=`date +%Y%m%d_%H%M%S`
BSERVERNAME=`hostname`

echo `date` 'Начало переноса'

count=$(find $PATH_SOURCE -type f -name "*${FILE_EXTENSION}" -not -path "$PATH_SOURCE/PREPROD/*" | wc -l)
if [ $count -gt 0 ]; then
    echo "Нашла $count файлов"
else
    echo "Нет файлов для переноса"
	exit
fi

# Создание временной директории, куда будут перенесены файлы
BTEMPDIR=/tmp/$BDATEFORMAT
mkdir -p $BTEMPDIR
chmod 777 $BTEMPDIR
cd $BTEMPDIR

if [ ! -z "$PATH_SOURCE" ]; then
    # Переносим файлы в tmp директорий
    find $PATH_SOURCE -type f -name "*${FILE_EXTENSION}" -not -path "$PATH_SOURCE/PREPROD/*" -exec mv {} $BTEMPDIR/ \;
fi

# Переименовываю файлы
cd $BTEMPDIR
for file in *${FILE_EXTENSION}; do
  mv "./${file}" "./FOOD_${file}"
done


# Копирование на внешний ресурс
sftp -P10022 -o KexAlgorithms=diffie-hellman-group14-sha1 -o BatchMode=no -b - $PATH_DESTINATION<<EOC
cd out
mput *${FILE_EXTENSION}
EOC

# Сжимаем конечный архив
echo `date` 'Сжимаю архив' $BSERVERNAME-$BDATEFORMAT.tar.gz
cd $BTEMPDIR
tar cfz $PATH_SOURCE/../EXPORT_ARCH/$BSERVERNAME-$BDATEFORMAT.tar.gz .
cd ..

if [ "${DO_DELETE}" == "1" ]; then
    if [ -f $PATH_SOURCE/../EXPORT_ARCH/$BSERVERNAME-$BDATEFORMAT.tar.gz ]; then
        echo `date` 'Удаляю временные файлы после бэкапа'
        rm -rf /tmp/$BDATEFORMAT
    fi
fi

echo `date` 'Удаляю старые архивы'
find $PATH_SOURCE/../EXPORT_ARCH -type f -name $BSERVERNAME-*.tar.gz -mtime +365 -delete

echo `date` 'Работа завершена'
exit
