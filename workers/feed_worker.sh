#!/bin/bash

# Cargar configuraciones
source "$(dirname "$0")/../config/elasticsearch.conf"
source "$(dirname "$0")/../config/aws.conf"

# Directorio donde se almacenan los jobs
JOB_DIR="$(dirname "$0")/../jobs"
PROCESSED_DIR="$(dirname "$0")/../jobs/processed"
FAILED_DIR="$(dirname "$0")/../jobs/failed"

# Crear directorios necesarios
mkdir -p "$PROCESSED_DIR" "$FAILED_DIR"

# Función para procesar un job
process_job() {
    local job_file=$1
    local job_id=$(basename "$job_file" .sh)
    
    echo "Procesando job: $job_id"
    
    # Ejecutar el job
    bash "$job_file"
    local result=$?
    
    if [ $result -eq 0 ]; then
        echo "Job completado con éxito: $job_id"
        # Mover a procesados
        mv "$job_file" "${PROCESSED_DIR}/"
        return 0
    else
        echo "Error al procesar job: $job_id (código: $result)"
        # Mover a fallidos
        mv "$job_file" "${FAILED_DIR}/"
        return 1
    fi
}

# Función para ejecutar el worker
run_worker() {
    echo "Iniciando worker..."
    
    # Procesar todos los jobs disponibles
    while true; do
        # Buscar jobs
        jobs=$(find "$JOB_DIR" -maxdepth 1 -name "*.sh" | sort)
        
        # Si no hay jobs, esperar y verificar nuevamente
        if [ -z "$jobs" ]; then
            echo "No hay jobs para procesar. Esperando..."
            sleep 10
            continue
        fi
        
        # Procesar cada job
        echo "Encontrados $(echo "$jobs" | wc -l) jobs para procesar."
        
        for job in $jobs; do
            process_job "$job"
            # Esperar un momento entre jobs para no sobrecargar los servicios
            sleep 2
        done
    done
}

# Función para reintentar jobs fallidos
retry_failed_jobs() {
    echo "Reintentando jobs fallidos..."
    
    # Buscar jobs fallidos
    failed_jobs=$(find "$FAILED_DIR" -name "*.sh" | sort)
    
    # Si no hay jobs fallidos, terminar
    if [ -z "$failed_jobs" ]; then
        echo "No hay jobs fallidos para reintentar."
        return 0
    fi
    
    # Reintentar cada job fallido
    echo "Encontrados $(echo "$failed_jobs" | wc -l) jobs fallidos para reintentar."
    
    for job in $failed_jobs; do
        job_id=$(basename "$job" .sh)
        echo "Reintentando job: $job_id"
        
        # Mover de nuevo al directorio de jobs
        cp "$job" "${JOB_DIR}/"
    done
    
    echo "Jobs fallidos movidos para reintento."
}

# Verificar si se pide reintentar los jobs fallidos
if [ "$1" = "--retry" ]; then
    retry_failed_jobs
    exit 0
fi

# Iniciar el worker
run_worker