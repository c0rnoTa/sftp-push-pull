#!/bin/bash

# Скрипт скачивания XML файлов с другого сервера себе
# Разработал Антон Захаров hello@antonzakharov.ru

################
# КОНФИГУРАЦИЯ #
################

# Путь где находятся файлы
PATH_DESTINATION=/home/vbrr-ow/incoming/

# откуда скачивать файлы
PATH_SOURCE=REMOTEUSER@10.0.0.1:/To_REMOTEUSER/

# Удалять скаченные файлы
DO_DELETE=1

##########################
# НАЧАЛО ПЕРЕНОСА ФАЙЛОВ #
##########################

# Инициализируем переменные
BDATEFORMAT=`date +%Y%m%d_%H%M%S`
BSERVERNAME=`hostname`

echo `date` 'Проверяю количество файлов на удалённом сервере'

count=$(echo ls *.xml | sftp "$PATH_SOURCE" | grep -v '^sftp>' | grep -v 'Changing' | wc -l)

if [ $count -gt 0 ]; then
    echo `date` "Нашла $count файлов. Получаю их список."
    XMLFILES=$(echo ls *.xml | sftp "$PATH_SOURCE" | grep -v '^sftp>' | grep -v 'Changing' )
else
    echo `date` "Нет файлов для переноса"
	exit
fi

if [ ! -d "$PATH_DESTINATION" ]; then
  mkdir -p "$PATH_DESTINATION"
  cd "$PATH_DESTINATION"
fi

for xmlfile in ${XMLFILES}; do
    echo `date` "Переношу файл $xmlfile"
    sftp "${PATH_SOURCE}${xmlfile}" "${PATH_DESTINATION}/${xmlfile}"
    if [ -f "${PATH_DESTINATION}/${xmlfile}" ];then
        if [ "${DO_DELETE}" == "1" ]; then
            echo `date` "Удаляю $xmlfile на удалённом сервере"
            echo rm "$xmlfile" | sftp "$PATH_SOURCE"
        fi
    fi
done

echo `date` 'Работа завершена'
exit