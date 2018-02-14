Jenkins API Client
==================

[![versión gema](http://img.shields.io/gem/v/jenkins_api_client.svg)][gema]
[![Estado de compilación](http://img.shields.io/travis/arangamani/jenkins_api_client.svg)][travis]
[![Estado de dependencia](http://img.shields.io/gemnasium/arangamani/jenkins_api_client.svg)][gemnasio]
[![Código Clima](http://img.shields.io/codeclimate/github/arangamani/jenkins_api_client.svg)][clima de código]

[gema]:https://rubygems.org/gems/jenkins_api_client
[travis]:http://travis-ci.org/arangamani/jenkins_api_client
[gemnasio]:https://gemnasium.com/arangamani/jenkins_api_client
[clima de código]:https://codeclimate.com/github/arangamani/jenkins_api_client

Copyright y copia; 2012-2017, Kannan Manickam [![endosar](http://api.coderwall.com/arangamani/endorsecount.png)](http://coderwall.com/arangamani)
Bibliotecas de clientes para comunicarse con un servidor de Jenkins CI y administrar tareas de forma programática.

Canal IRC: ##jenkins-api-client(on freenode)

Lista de correo:jenkins_api_client@googlegroups.com

Grupo de Google:https://groups.google.com/group/jenkins_api_client

VISIÓN DE CONJUNTO:
---------
Este proyecto es un simple cliente API para interactuar con Jenkins Continuous 
Servidor de integración. Jenkins proporciona tres tipos de acceso remoto API.
1. API XML, 2. API JSON y 3. API Python. Este proyecto tiene como objetivo consumir el 
JSON API y proporciona algunas funciones útiles para controlar trabajos en Jenkins 
programáticamente A pesar de que Jenkins proporciona una increíble interfaz de usuario para controlar 
trabajos, sería bueno y útil tener una interfaz programable para que podamos gestionar de forma 
dinámica y automática trabajos y otros artefactos.

DETALLES:
--------
Actualmente, estos proyectos solo brindan funcionalidad para
<tt>interfaces de trabajos, nodo, vista, sistema y cola de compilación</tt>.

USO:
------

### Instalación

Instale jenkins_api_client con <tt>sudo gem install jenkins_api_client</tt>
Incluye esta gema en tu código como una declaración obligatoria.

requiere 'jenkins_api_client'

### Uso con IRB

Si solo quiere jugar con él y no quiere escribir un guión,
solo puede usar el script de lanzador de IRB que está disponible en
<tt>scripts / login_with_irb.rb</tt>. Pero asegúrate de tener tus credenciales
disponible en la ubicación correcta. Por defecto, el script asume que tienes
su archivo de credenciales en<tt> ~ / .jenkins_api_client / login.yml</tt>. Si no lo haces
prefiere esta ubicación y le gustaría usar una ubicación diferente, solo modifique
esa secuencia de comandos para apuntar a la ubicación donde existe el archivo de credenciales.

    ruby scripts/login_with_irb.rb
    
Verás que entró en la sesión IRB y puedes jugar con la API
cliente con el objeto <tt>@client</tt> que ha devuelto.

### Autenticación 

El suministro de credenciales al cliente es opcional, ya que no todas las instancias 
de Jenkins requiere autenticación. Este proyecto admite dos tipos de base de contraseñas 
de autenticación. Puedes simplemente la contraseña simple usando el parámetro de la <tt>contraseña</tt>. 
Si no prefiere dejar contraseñas simples en el archivo de credenciales, 
puedes codificar tu contraseña en formato base 64 y usar <tt>contraseña_base64 </tt>
parámetro para especificar la contraseña en los argumentos o en las credenciales 
archivo. Para usar el cliente sin credenciales, simplemente deje fuera ellos parámetros <tt>nombre de usuario</tt> y <tt>contraseña</tt>. La <tt>contraseña</tt>el parámetro solo es necesario si se especifica <tt>nombre de usuario</tt>.

#### Uso con Open ID

Es muy simple autenticarse con su servidor Jenkins que tiene la Open ID autenticación habilitada Tendrás que obtener tu símbolo de API y usar el símbolo API como contraseña. Para obtener el símbolo API, vaya a su configuración de usuario y haga clic en 'Mostrar el símbolo API'. Utilice este símbolo para el parámetro de `contraseña` cuandoinicializando el cliente.

### Sitio Cruzado (XSS) y Soporte de Migas

Soporte para migas Jenkins ha sido agregado. Estos permiten una aplicación para utilizar los métodos de API POST de Jenkins sin requerir 'Prevenir el sitio cruzado' Solicite falsificación explotada para ser deshabilitado. La API se registrará con el Servidor de Jenkins para determinar si las migas están habilitadas o no, y úsalas si es apropiado.

```ruby
@client = JenkinsApi::Client.new(:server_ip => '0.0.0.0',
         :nombre de usuario => 'cualquier nombre', :contraseña => 'contraseña secreta')
# La siguiente llamada devolverá todos los trabajos que coincidan 'Prueba de Trabajo'
puts @client.job.list("^Testjob")
```

El siguiente ejemplo pasa los contenidos del archivo YAML. Un ejemplo de archivo yaml está situado en <tt>config/login.yml.example</tt>.

```Ruby
@client = JenkinsApi::Client.new(YAML.load_file(File.expand_path(
  "~/.jenkins_api_client/login.yml", __FILE__)))
# La siguiente llamada enumera todos los trabajos
puts @client.job.list_all
```

### Encadenamiento y construcción de trabajos

A veces queremos agregar ciertos trabajos como proyectos posteriores y ejecutarlos
secuencialmente. El siguiente ejemplo explicará cómo se podría hacer esto.

```ruby
require 'jenkins_api_client'

# Queremos filtrar todos los trabajos que comienzan con 'test_job'
# Just write a regex to match all the jobs that start with 'test_job'
jobs_to_filter = "^test_job.*"

# Crea una instancia para jenkins_api_client
@client = JenkinsApi::Client.new(YAML.load_file(File.expand_path(
  "~/.jenkins_api_client/login.yml", __FILE__)))

# Obtenga una lista filtrada de trabajos del servidor
trabajos = @client.job.list(jobs_to_filter)

# Encadena todos los trabajos con 'éxito' como el límite
# El método de cadena devolverá los trabajos que están en la cabeza de la secuencia
# Este método también eliminará cualquier encadenamiento existente
initial_jobs = @client.job.chain(jobs, 'success', ["all"])

# Ahora que tenemos los trabajos iniciales, podemos construirlos
# La función de compilación devuelve un código de la API que debería ser 201 si
# la construcción fue exitosa, para Jenkins >= v1.519
# Para versiones anteriores a v1.519, el código de éxito es 302.
code = @client.job.build(initial_jobs[0])
raise "Could not build the job specified" unless code == '201'
```

En el ejemplo anterior, es posible que hayas notado que el método de cadena devuelve una matriz en lugar de un solo trabajo. Hay una razón detrás de esto. En cadena simple,como el del ejemplo anterior, todos los trabajos especificados están encadenados uno por uno. Pero en algunos casos pueden no depender de los trabajos anteriores y que se desee ejecutar algunos trabajos de forma paralela. Solo tenemos que especificar eso como un parámetro.

Por ejemplo: <tt>parallel=3</tt> in the parameter list to the <tt>chain</tt>
método tomará los primeros tres trabajos y los encadenará con los siguientes tres trabajos
y así sucesivamente hasta que llega al final de la lista.

Hay otra opción de filtro que puede especificar para que el método solo tome
trabajos que están en un estado particular. En caso de que si queremos construir solo trabajos
que son fallidos o inestables, podemos lograr eso pasando a los estados en
el tercer parámetro. En el ejemplo anterior, queríamos construir todos los trabajos. Si solo
quiere construir trabajos fallidos e inestables, solo pase
<tt>["failure", "unstable"]</tt>.Además, si pasa una matriz vacía,
suponga que desea considerar todos los trabajos y no se realizará ningún filtrado.

Hay otro parámetro llamado <tt>límite</tt> puedes especificar para el
encadenamiento y esto se usa para decidir si seguir adelante con el próximo trabajo
en la cadena o no. Un <tt>Éxito</tt> pasará al siguiente trabajo solo si el
la construcción actual tiene éxito, <tt>fracaso</tt> pasará al siguiente trabajo, incluso si el
la construcción falla, y <tt>inestable</tt> se moverá al trabajo incluso si la construcción es
inestable.

La siguiente llamada a la <tt>cadena</tt> método considerará solo los trabajos fallados e inestables, y tamién en la cadena luego con la 'falla' como límite, y también encadenará tres trabajos en paralelo.

```ruby
initial_jobs = @client.job.chain(jobs, 'failure', ["failure", "unstable"], 3)
# Recibiremos tres trabajos como resultado y podemos construirlos todos
initial_jobs.each do |job|
  code = @client.job.build(job)
  raise "Unable to build job: #{job}" unless code == '201'
end
```

### Configuración de complementos

Dada la abundancia de complementos para Jenkins, ahora brindamos una forma extensible de configurar trabajos y configurar sus complementos. En este momento, la gema se envía con el hipchatplugin, con más complementos a seguir en el futuro. 

```ruby
hipchat_settings = JenkinsApi::Client::PluginSettings::Hipchat.new({
  :room => '10000',
  :start_notification => true,
  :notify_success => true,
  :notify_aborted => true,
  :notify_not_built => true,
  :notify_unstable => true,
  :notify_failure => true,
  :notify_back_to_normal => true,
})

client = JenkinsApi::Client.new(
  server_url: jenkins_server,
  username: username,
  password: password
)

# NOTA: los complementos pueden ser eliminados, por lo que si tuviera otro complemento podría pasarse
# a la nueva llamada a continuación como otra arg después de hipchat
job = JenkinsApi::Client::Job.new(client, hipchat)

```

Escribir sus propios complementos también es sencillo. Heredar de la JenkinsApi :: Cliente::Configurar Complemento::Clase base y anula el método de configuración.Los trabajos de Jenkins se configuran usando xml, así que solo necesita averiguar dónde configuró para enganchar en su configuración de complemento.

Aquí hay un ejemplo de un complemento escrito para configurar un trabajo para la limpieza del espacio de trabajo.

```ruby
module JenkinsApi
  class Client
    module PluginSettings
      class WorkspaceCleanup < Base

        # @option params [Boolean] :delete_dirs (false)
        #   whether to also apply pattern on directories
        # @option params [String] :cleanup_parameters
        # @option params [String] :external_delete
        def initialize(params={})
          @params = params
        end

        # Crear o actualizar un trabajo con parámetros dados como hash en lugar de xml
        # Esto le da cierta flexibilidad para crear / actualizar trabajos simples para que el
        # user doesn't have to learn about handling xml.
        #
        # @param xml_doc [Nokogiri::XML::Document] xml document to be updated with 
        # la configuración de complementos
        #
        # @return [Nokogiri::XML::Document]
        def configure(xml_doc)
          xml_doc.tap do |doc|
            Nokogiri::XML::Builder.with(doc.at('buildWrappers')) do |build_wrappers|
              build_wrappers.send('hudson.plugins.ws__cleanup.PreBuildCleanup') do |x|
                x.deleteDirs @params.fetch(:delete_dirs) { false }
                x.cleanupParameter @params.fetch(:cleanup_parameter) { '' }
                x.externalDelete @params.fetch(:external_delete) { '' }
              end
            end
          end
        end
      end
    end
  end
end
```

Actualmente, el complemento skype todavía se configura directamente en el trabajo jenkins. Esta voluntad
probablemente se extraiga en su propio complemento en el futuro cercano, pero mantendremos
compatibilidad hacia atrás hasta después de un período oficial de desaprobación.

### Esperando a que comience una construcción / Obtener el número de compilación
Las versiones más nuevas de Jenkins (comenzando con la versión 1.519) hacen que sea más fácil parauna aplicación para determinar el número de compilación para una solicitud de 'compilación'. (previamente habrá un cierto grado de conjetura involucrado). La nueva versión en realidad devuelve información que permite a jenkins_api_client verificar la cola de compilaciónpara el trabajo y ver si ya ha comenzado (una vez que ha comenzado, la construcciónnumero esta disponible.

Si desea aprovechar este enfoque de no intervención, el método de compilaciónadmite un hash 'opts' adicional que le permite especificar cuánto tiempo desea esperar a que comience la construcción.

#### Antiguo Jenkins vs Nuevo Jenkins (1.519+)

##### Antiguo (v < 1.519)
El parámetro 'opts' funcionará con versiones anteriores de Jenkins con las siguientes advertencias:
* la opción de 'cancelar_el_tiempo_de_espera_de_incicio_de_compilación' no tendrá efecto.
* El número_de_compilación se calcula llamando al 'número_de_compilación_actual' y agregando
  1 antes de que se inicie la construcción. Esto podría romperse si hay múltiples
  entidades ejecutando compilaciones en el mismo trabajo, o hay compilaciones en cola.

##### Nuevo (v >= 1.519)
* Todas las opciones funcionan, y el número de compilación se determina con precisión a partir de la cola
   información.
* El código de éxito del desencadenador de compilación ahora es 201 (Creado). Anteriormente era 302.

#### Iniciar una compilación y devolver el número_de_compilación

##### Mínimo requerido
```ruby
# Opciones mínimas requeridas
opts = {'build_start_timeout' => 30}
@client.job.build(job_name, job_params || {}, opts)
```
Este método se bloqueará durante hasta 30 segundos, mientras espera que la compilación empiece. En lugar de devolver un código de estado http, 
devolverá el número_de_compilación, o si la compilación no se ha iniciado, se generará 'Tiempo expirado::Error' Nota: para mantener la compatibilidad heredada, 
pasando 'verdadero' establecerá el tiempo de esperaal tiempo de espera predeterminado especificado al crear el @client.

##### Cancelación automática de la cola de compilación en tiempo de espera
```ruby
#Espere hasta 30 segundos e intente cancelar la creación en cola
opts = {'build_start_timeout' => 30,
        'cancel_on_build_start_timeout' => true}
@client.job.build(job_name, job_params || {}, opts)
```
Este método se bloqueará durante 30 segundos, mientras espera la compilación decomienzo. En lugar de devolver un código de estado http, devolverá el número_de_compilación, o si la compilación no se inició, se generará 'Tiempo Expirado :: Error'.Antes de generar Tiempo expirado :: Error, intentará cancelar la cola 
construir, lo que impide que se inicie.

##### Obtener algunos comentarios mientras esperas
El parámetro opts admite dos valores a los que se pueden asignar objetos de proc(que será 'llamado'). Ambos son opcionales y solo se llamarán si se especifica en opts.
Inicialmente están destinados a ayudar con el progreso de ingreso.

* 'progress_proc' - se llama cuando el trabajo está inicialmente en cola, y periódicamente
   después de eso.
  * max_wait - the value of 'build_start_timeout'
  * current_wait -cuánto tiempo hemos estado esperando hasta ahora
  * poll_count - cuantas veces hemos sondeado la cola
* 'completion_proc' - llamado justo antes de regresar/Tiempo Expirado::Error
  * build_number - el número de compilación asignado (or nil if timeout)
  * cancelled - si la construcción fue cancelada (verdadero si es el 'nuevo' Jenkins
    y fue capaz de cancelar la compilación, de lo contrario es falso)

Para usar una clase de método, simplemente especifique 'instance.method (: method_name)', o usa un proc o lambda

```ruby
# Espere hasta 30 segundos, intente cancelar la creación en cola, avance
opts = {'build_start_timeout' => 30,
        'cancel_on_build_start_timeout' => true,
        'poll_interval' => 2,      # 2 is actually the default :)
        'progress_proc' => lambda {|max,curr,count| ... },
        'completion_proc' => lambda {|build_number,cancelled| ... }}
@client.job.build(job_name, job_params || {}, opts)
```
### Corriendo Jenkins CLI
Para correr [Jenkins CLI](https://wiki.jenkins-ci.org/display/JENKINS/Jenkins+CLI)

* autenticación con nombre de usuario/contraseña (obsoleto)

```ruby
@client = JenkinsApi::Client.new(:server_ip => '127.0.0.1',
         :Nombre de usuario => 'Cualquier Nombre', :contraseña => 'contraseña secreta')
# La siguiente llamada devolverá la versión de la instancia de Jenkins
puts @client.exec_cli("version")
```

* la autenticación con el archivo de clave pública/privada
recuerde cargar la clave pública a:

    `http://#{Server IP}:#{Server Port}/user/#{Username}/configure`

```ruby
@client = JenkinsApi::Client.new(:server_ip => '127.0.0.1',
         :identity_file => '~/.ssh/id_rsa')
# La siguiente llamada devolverá la versión de la instancia de Jenkins
coloque @client.exec_cli("version")
```

Antes de ejecutar la CLI, asegúrese de que se cumplan los siguientes requisitos:
* JRE/JDK 6 (o superior) está instalado y 'java' está en el entorno $PATH
   variable
* ElThe ```jenkins_api_client/java_deps/jenkins-cli.jar``` es requerido como el
   cliente para ejecutar la CLI. Puede recuperar los comandos disponibles accediendo
  the URL: ```http://<server>:<port>/cli```
* (Opcional) requerido si ejecuta Groovy Script a través de CLI, asegúrese
   el * usuario * tiene el guión privilegiado para ejecutar

### Usando con línea de comando
La interfaz de línea de comandos solo es compatible con la versión 0.2.0.
Ver ayuda usando <tt>jenkinscli ayuda</tt>

Hay tres formas de autenticación utilizando la interfaz de línea de comando
1. Pasar todas las credenciales e información del servidor usando parámetros de línea de comando
2. Pasar el archivo de credenciales como el parámetro de la línea de comando
3. Tener el archivo de credenciales en la ubicación predeterminada
   <tt>HOME/.jenkins_api_client/login.yml</tt>

### Depurar

A partir de v0.13.0, este parámetro de depuración se elimina. Use el registrador en su lugar. Ver el
la próxima sección para más información sobre esta opción.

### Iniciar sesión

A partir de v0.13.0, se presenta soporte para inicio de sesión. Dado que sería bueno tenerlas actividades de jenkins_api_client en un archivo de registro, esta característica se implementa utilizando la clase Inicio de sesión estándar de Ruby. Para usar esta característica,hay dos nuevos argumentos de entrada utilizados durante la inicialización del Cliente.

1. `:log_location` - Este argumento especifica la ubicación del archivo de registro. Una buena ubicación para los sistemas basados en Linux sería
   '/var/log/jenkins_api_client.log'.El valor predeterminado para estos valores es STDOUT. Esto imprimirá los mensajes de registro en la misma consola.
2. `:log_level` -Este argumento especifica el nivel de mensajes que se registrarán.
   It should be one of Logger::DEBUG (0), Logger::INFO (1), Logger::WARN (2),
   Logger::ERROR (3), Logger::FATAL (4). It can be specified either using the
   constants available in the Logger class or using these integers provided
   here. The default for this argument is Logger::INFO (1)

Si desea personalizar la funcionalidad que el incicio de sesión proporciona,
 como dejar viejos archivos de registro, abra el archivo de registro en el modo de agregar, cree su propio registrador y luego configurar eso en el cliente...

#### Ejemplos

```ruby
  @client = JenkinsApi::Client.new(...)
  # Cree un registrador que envejece el archivo de registro una vez que alcanza un cierto tamaño. Deja 10
  # "Viejos archivos de registro" y cada archivo trata de1,024,000 bytes.
  @client.logger = Logger.new('foo.log', 10, 1024000)
```
Por favor dirigirse a [Ruby
Logger](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/logger/rdoc/Logger.html) 
para más información.
