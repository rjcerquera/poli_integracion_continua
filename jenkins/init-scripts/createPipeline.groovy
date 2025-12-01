// Script Groovy para crear pipelines automáticamente
// Este script se ejecuta al iniciar Jenkins (init.groovy.d)
// Crea múltiples pipelines desde la carpeta pipelines/

import jenkins.model.Jenkins
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition
import org.jenkinsci.plugins.scriptsecurity.scripts.ScriptApproval

// Configuración de pipelines a crear
def pipelines = [
    [
        name: 'health-check-pipeline',
        path: '/var/jenkins_home/pipelines/health-check-pipeline/Jenkinsfile',
        description: 'Pipeline para verificar la conectividad y salud de todos los contenedores (MySQL, Laravel, Next.js, Gitea, Jenkins)',
        displayName: 'Health Check - Contenedores'
    ],
    [
        name: 'webhook-pipeline',
        path: '/var/jenkins_home/pipelines/webhook-pipeline/Jenkinsfile',
        description: 'Pipeline que se activa automáticamente cuando Gitea envía un webhook (push, pull request, etc.)',
        displayName: 'Webhook Pipeline - Gitea'
    ]
]

println "[Init Script] ╔════════════════════════════════════════════════════════════════╗"
println "[Init Script] ║  🚀 CREACIÓN AUTOMÁTICA DE PIPELINES                           ║"
println "[Init Script] ╚════════════════════════════════════════════════════════════════╝"
println ""

def createdPipelines = []
def skippedPipelines = []
def failedPipelines = []

pipelines.each { pipelineConfig ->
    def jobName = pipelineConfig.name
    def jenkinsfilePath = pipelineConfig.path
    
    try {
        // Verificar si el job ya existe
        def existingJob = Jenkins.instance.getItem(jobName)
        
        if (existingJob != null) {
            println "[Init Script] ⚠️  Job '${jobName}' ya existe, omitiendo creación."
            skippedPipelines.add(jobName)
            return
        }
        
        println "[Init Script] 📝 Creando pipeline: ${jobName}"
        
        // Leer el Jenkinsfile
        def jenkinsfile = new File(jenkinsfilePath)
        
        if (!jenkinsfile.exists()) {
            println "[Init Script] ⚠️  Jenkinsfile no encontrado en ${jenkinsfilePath}"
            println "[Init Script]    El job se puede crear manualmente desde la UI de Jenkins"
            failedPipelines.add([name: jobName, reason: "Jenkinsfile no encontrado: ${jenkinsfilePath}"])
            return
        }
        
        def pipelineScript = jenkinsfile.text
        
        if (!pipelineScript || pipelineScript.trim().isEmpty()) {
            println "[Init Script] ⚠️  Jenkinsfile vacío en ${jenkinsfilePath}"
            failedPipelines.add([name: jobName, reason: "Jenkinsfile vacío"])
            return
        }
        
        // Crear el job
        def job = Jenkins.instance.createProject(WorkflowJob.class, jobName)
        job.definition = new CpsFlowDefinition(pipelineScript, false)
        job.description = pipelineConfig.description
        job.displayName = pipelineConfig.displayName
        
        // Guardar el job
        job.save()
        
        createdPipelines.add(jobName)
        println "[Init Script] ✅ Pipeline '${jobName}' creado exitosamente!"
        println "[Init Script]    URL: http://localhost:8081/job/${jobName}/"
        
    } catch (Exception e) {
        println "[Init Script] ❌ Error al crear pipeline '${jobName}': ${e.getMessage()}"
        failedPipelines.add([name: jobName, reason: e.getMessage()])
        // No fallar el inicio de Jenkins si hay un error
    }
}

// Resumen
println ""
println "[Init Script] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
println "[Init Script] 📊 RESUMEN DE CREACIÓN DE PIPELINES"
println "[Init Script] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
println ""

if (createdPipelines.size() > 0) {
    println "[Init Script] ✅ Pipelines creados (${createdPipelines.size()}):"
    createdPipelines.each { name ->
        println "[Init Script]    - ${name}"
    }
    println ""
}

if (skippedPipelines.size() > 0) {
    println "[Init Script] ⚠️  Pipelines omitidos (${skippedPipelines.size()}):"
    skippedPipelines.each { name ->
        println "[Init Script]    - ${name} (ya existe)"
    }
    println ""
}

if (failedPipelines.size() > 0) {
    println "[Init Script] ❌ Pipelines fallidos (${failedPipelines.size()}):"
    failedPipelines.each { failure ->
        println "[Init Script]    - ${failure.name}: ${failure.reason}"
    }
    println ""
}

// Aprobar todos los scripts pendientes
println "[Init Script] 🔐 Aprobando scripts pendientes..."
approveAllPendingScripts()

println ""
println "[Init Script] ✅ Proceso de inicialización de pipelines completado"
println ""

// Función para aprobar todos los scripts pendientes
def approveAllPendingScripts() {
    try {
        def scriptApproval = ScriptApproval.get()
        def pendingScripts = scriptApproval.getPendingScripts()
        if (pendingScripts != null && pendingScripts.size() > 0) {
            println "[Init Script]    Aprobando ${pendingScripts.size()} script(s) pendiente(s)..."
            pendingScripts.each { pending ->
                try {
                    scriptApproval.approveScript(pending.getHash())
                    println "[Init Script]    ✅ Script pendiente aprobado: ${pending.getHash()}"
                } catch (Exception e) {
                    println "[Init Script]    ⚠️  Error al aprobar script ${pending.getHash()}: ${e.getMessage()}"
                }
            }
        } else {
            println "[Init Script]    ℹ️  No hay scripts pendientes de aprobar"
        }
    } catch (Exception e) {
        println "[Init Script]    ⚠️  Error al obtener scripts pendientes: ${e.getMessage()}"
    }
}
