




############################################################################################################
njs_fs                    = require 'fs'
njs_path                  = require 'path'
njs_cp                    = require 'child_process'
#...........................................................................................................
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
log_                      = TRM.log.bind TRM
badge                     = 'cndmon'
log                       = TRM.get_logger 'plain', badge
info                      = TRM.get_logger 'info',  badge
whisper                   = TRM.get_logger 'whisper',  badge
alert                     = TRM.get_logger 'alert', badge
warn                      = TRM.get_logger 'warn',  badge
help                      = TRM.get_logger 'help',  badge
echo                      = TRM.echo.bind TRM
#...........................................................................................................
# https://github.com/bevry/watchr
watchr                    = require 'watchr'
#...........................................................................................................
server                    = null
server_is_running         = no
### TAINT: globals are bad, and so is this module-global state.keeping: ###
_restart_on_exit          = no
home                      = process.cwd()
options_route             = njs_path.join home, 'monitor-options'
version                   = ( require '../package.json' )[ 'version' ]



############################################################################################################
### Show opening banner: ###
log()
log TRM.grey  '      * * * * * * * * * * * * * * * * * * '
log TRM.steel "              CoffeeNode Monitor          "
log TRM.steel "      the friendly file & process watcher "
log TRM.grey  "                  (v#{version}) "
log TRM.grey  '      * * * * * * * * * * * * * * * * * * '


############################################################################################################
### Load options: ###
try
  O = require options_route
catch error
  if /^Cannot find module/.test error[ 'message' ]
    log()
    alert "unable to load #{TRM.lime options_route}"
    alert "please copy file", TRM.lime 'coffeenode-monitor/monitor-options.json'
    alert "to", TRM.lime home
    alert "and edit it to match your needs"
    log()
    process.exit()
  else
    throw error


############################################################################################################
### Preprocess settings: ###
if O[ 'watch-routes' ]?
  null
  # for route, idx in O[ 'watch-routes' ]
  #   O[ 'watch-routes' ][ idx ] = njs_path.join home, route
else
  O[ 'watch-routes' ] = [ home, ]
#...........................................................................................................
if O[ 'start' ]?
  null
  # O[ 'start' ] = njs_path.join home, O[ 'start' ]
else
  O[ 'start' ] = './lib/start.js'


############################################################################################################
### Report settings: ###
log()
for name, value of O
  log ( TRM.grey 'setting' ), ( TRM.gold "#{name}:" ), ( TRM.lime rpr value )


#===========================================================================================================
# SERVER METHODS
#-----------------------------------------------------------------------------------------------------------
start = ->
  ### TAINT: module-global state ###
  _restart_on_exit  = no
  info 'start:', O[ 'start' ]
  server            = njs_cp.fork O[ 'start' ]
  # TRM.dir '©34e server', server
  #.........................................................................................................
  server.on 'error', ( error ) ->
    alert error
  #.........................................................................................................
  server.on 'close', ( code, signal ) ->
    server_is_running = no
    if code?
      warn "process with PID #{server[ 'pid' ]} received signal ##{code}"
    if _restart_on_exit
      start()
    else
      help "process will be restarted on code change"
  #.........................................................................................................
  server_is_running = yes



#-----------------------------------------------------------------------------------------------------------
stop_server = ( restart_on_exit = no ) ->
  ### TAINT: module-global state ###
  _restart_on_exit = restart_on_exit
  if server_is_running
    info "stopping process with PID #{server.pid}"
    server.kill 'SIGTERM'
  else
    # log TRM.red "server with PID #{server.pid} already shutdown"
    server.emit 'close'


#-----------------------------------------------------------------------------------------------------------
restart_server = ->
  stop_server yes



#===========================================================================================================
# FILE WATCHER
#-----------------------------------------------------------------------------------------------------------
### TAINT we need a solution for this: ###
watchr_options =
  paths: O[ 'watch-routes' ]
  #.........................................................................................................
  listeners:

    #.......................................................................................................
    error: ( error ) ->
      log TRM.red "an error occured:", error

    #.......................................................................................................
    change: ( type, route, current_stat, previous_stat ) ->
      info "change:", route
      restart_server()

    #.......................................................................................................
    watching: ( error, watchers ) ->
      throw error if error?
      log()
      for filename, watcher of watchers[ 'children' ]
        whisper "watching #{watcher[ 'path' ]}"


# ############################################################################################################
# log TRM.pink watchr_options
watchr.watch watchr_options
start()


# log TRM.pink process.argv
# log TRM.green process.cwd()












