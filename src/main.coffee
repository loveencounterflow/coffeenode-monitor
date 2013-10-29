
### TAINT MONITOR shouldn't start a server when executed / required.
This is a library, not an executable. ###





############################################################################################################
njs_fs                    = require 'fs'
njs_path                  = require 'path'
njs_cp                    = require 'child_process'
#...........................................................................................................
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
log                       = TRM.log.bind TRM
echo                      = TRM.echo.bind TRM
#...........................................................................................................
# https://github.com/bevry/watchr
watchr                    = require 'watchr'
#...........................................................................................................
server                    = null
server_is_running         = no
### TAINT: globals are bad, and so is this module-global state.keeping: ###
_restart_on_exit          = no
home                      = njs_path.join __dirname, '../src'

#===========================================================================================================
# SERVER METHODS
#-----------------------------------------------------------------------------------------------------------
start_server = ->
  ### TAINT: module-globale state ###
  _restart_on_exit  = no
  server            = njs_cp.fork './lib/start.js'
  # TRM.dir '©34e server', server
  #.........................................................................................................
  server.on 'error', ( error ) ->
    log TRM.red error
  #.........................................................................................................
  server.on 'close', ( code, signal ) ->
    server_is_running = no
    if code?
      log TRM.red "process with PID #{server[ 'pid' ]} received signal ##{code}"
    if _restart_on_exit
      start_server()
    else
      log TRM.gold "awaiting code change"
  #.........................................................................................................
  server_is_running = yes



#-----------------------------------------------------------------------------------------------------------
stop_server = ( restart_on_exit = no ) ->
  ### TAINT: module-globale state ###
  _restart_on_exit = restart_on_exit
  if server_is_running
    log TRM.red "stopping process with PID #{server.pid}"
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
home_of_jzrds = njs_path.join ( njs_path.dirname require.resolve 'jizura-datasources' ), '..'
watchr_options =
  paths: [ home, home_of_jzrds, ]
  #.........................................................................................................
  listeners:

    #.......................................................................................................
    error: ( error ) ->
      log TRM.red "an error occured:", error

    #.......................................................................................................
    change: ( type, route, current_stat, previous_stat ) ->
      log TRM.gold "change:", route
      restart_server()

    #.......................................................................................................
    watching: ( error, watchers ) ->
      throw error if error?
      for filename, watcher of watchers[ 'children' ]
        log TRM.grey "watching #{watcher[ 'path' ]}"


############################################################################################################
log TRM.pink watchr_options
watchr.watch watchr_options
start_server()

















