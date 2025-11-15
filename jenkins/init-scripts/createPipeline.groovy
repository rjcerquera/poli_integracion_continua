// Script Groovy para crear el pipeline de health check automáticamente
// Este script se ejecuta al iniciar Jenkins (init.groovy.d)

import jenkins.model.Jenkins
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition
import org.jenkinsci.plugins.scriptsecurity.scripts.ScriptApproval

def jobName = 'health-check-pipeline'

try {
    // Verificar si el job ya existe
    def existingJob = Jenkins.instance.getItem(jobName)
    
    if (existingJob != null) {
        println "[Init Script] Job '${jobName}' ya existe, omitiendo creación."
        // Aprobar todos los scripts pendientes
        approveAllPendingScripts()
        return
    }
    
    println "[Init Script] Creando pipeline job: ${jobName}"
    
    // Leer el Jenkinsfile
    def jenkinsfilePath = '/var/jenkins_home/jenkins-pipeline/Jenkinsfile'
    def jenkinsfile = new File(jenkinsfilePath)
    
    if (!jenkinsfile.exists()) {
        println "[Init Script] ⚠️  Jenkinsfile no encontrado en ${jenkinsfilePath}"
        println "[Init Script] El job se puede crear manualmente desde la UI de Jenkins"
        println "[Init Script] O copiar el Jenkinsfile a: ${jenkinsfilePath}"
        return
    }
    
    def pipelineScript = jenkinsfile.text
    
    // Crear el job
    def job = Jenkins.instance.createProject(WorkflowJob.class, jobName)
    job.definition = new CpsFlowDefinition(pipelineScript, false)
    job.description = 'Pipeline para verificar la conectividad y salud de todos los contenedores (MySQL, Laravel, Next.js, Gitea, Jenkins)'
    job.displayName = 'Health Check - Contenedores'
    
    // Guardar el job
    job.save()
    
    // Aprobar todos los scripts pendientes (se ejecutará después de que Jenkins detecte scripts pendientes)
    println "[Init Script] Nota: Los scripts del pipeline se aprobarán automáticamente cuando se ejecuten por primera vez"
    
    println "[Init Script] ✅ Pipeline job '${jobName}' creado exitosamente!"
    println "[Init Script] El pipeline está disponible en: http://localhost:8081/job/${jobName}/"
    
} catch (Exception e) {
    println "[Init Script] ❌ Error al crear el pipeline job: ${e.getMessage()}"
    println "[Init Script] Stack trace: ${e.getStackTrace().join('\n')}"
    // No fallar el inicio de Jenkins si hay un error
}

// Función para aprobar todos los scripts pendientes
def approveAllPendingScripts() {
    try {
        def scriptApproval = ScriptApproval.get()
        def pendingScripts = scriptApproval.getPendingScripts()
        if (pendingScripts != null && pendingScripts.size() > 0) {
            println "[Init Script] Aprobando ${pendingScripts.size()} script(s) pendiente(s)..."
            pendingScripts.each { pending ->
                try {
                    scriptApproval.approveScript(pending.getHash())
                    println "[Init Script] ✅ Script pendiente aprobado: ${pending.getHash()}"
                } catch (Exception e) {
                    println "[Init Script] ⚠️  Error al aprobar script ${pending.getHash()}: ${e.getMessage()}"
                }
            }
        } else {
            println "[Init Script] No hay scripts pendientes de aprobar"
        }
    } catch (Exception e) {
        println "[Init Script] ⚠️  Error al obtener scripts pendientes: ${e.getMessage()}"
    }
}


