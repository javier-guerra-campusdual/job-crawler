#!/bin/bash

# Cargar configuración
source "$(dirname "$0")/../config/aws.conf"

# Función para verificar si un objeto existe en S3
s3_object_exists() {
    local key=$1
    
    aws s3 ls "s3://${S3_BUCKET}/${key}" > /dev/null 2>&1
    return $?
}

# Función para subir un archivo a S3
s3_upload_file() {
    local file=$1
    local key=$2
    
    aws s3 cp "$file" "s3://${S3_BUCKET}/${key}"
    return $?
}

# Función para subir contenido directamente a S3
s3_upload_content() {
    local content=$1
    local key=$2
    
    echo "$content" | aws s3 cp - "s3://${S3_BUCKET}/${key}"
    return $?
}

# Función para descargar un archivo de S3
s3_download_file() {
    local key=$1
    local destination=$2
    
    aws s3 cp "s3://${S3_BUCKET}/${key}" "$destination"
    return $?
}

# Función para listar objetos en un prefijo de S3
s3_list_objects() {
    local prefix=$1
    
    aws s3 ls "s3://${S3_BUCKET}/${prefix}" --recursive
    return $?
}

# Función para crear un bucket de S3 si no existe
s3_create_bucket() {
    # Verificar si el bucket existe
    aws s3 ls "s3://${S3_BUCKET}" > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        # Crear el bucket
        aws s3 mb "s3://${S3_BUCKET}"
        echo "Bucket creado: ${S3_BUCKET}"
    else
        echo "El bucket ya existe: ${S3_BUCKET}"
    fi
}

# Crear el bucket automáticamente si es necesario
s3_create_bucket