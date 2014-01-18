(function() {
  var O, TRM, alert, badge, debug, echo, error, help, home, info, log, log_, name, njs_cp, njs_fs, njs_path, options_route, restart_server, rpr, server, server_is_running, start, stop_server, value, version, warn, watchr, watchr_options, whisper, _restart_on_exit, _start;

  njs_fs = require('fs');

  njs_path = require('path');

  njs_cp = require('child_process');

  TRM = require('coffeenode-trm');

  rpr = TRM.rpr.bind(TRM);

  log_ = TRM.log.bind(TRM);

  badge = 'cndmon';

  log = TRM.get_logger('plain', badge);

  info = TRM.get_logger('info', badge);

  whisper = TRM.get_logger('whisper', badge);

  debug = TRM.get_logger('debug', badge);

  alert = TRM.get_logger('alert', badge);

  warn = TRM.get_logger('warn', badge);

  help = TRM.get_logger('help', badge);

  echo = TRM.echo.bind(TRM);

  watchr = require('watchr');

  server = null;

  server_is_running = false;


  /* TAINT: globals are bad, and so is the module-global state-keeping below: */

  _restart_on_exit = false;

  home = process.cwd();

  options_route = njs_path.join(home, 'monitor-options');

  version = (require('../package.json'))['version'];


  /* Show opening banner: */

  log();

  log(TRM.grey('      * * * * * * * * * * * * * * * * * * '));

  log(TRM.steel("              CoffeeNode Monitor          "));

  log(TRM.steel("      the friendly file & process watcher "));

  log(TRM.grey("                  (v" + version + ") "));

  log(TRM.grey('      * * * * * * * * * * * * * * * * * * '));


  /* Load options: */

  info("loading configuration settings from", TRM.lime(options_route));

  try {
    O = require(options_route);
  } catch (_error) {
    error = _error;
    if (/^Cannot find module/.test(error['message'])) {
      log();
      alert("unable to load " + (TRM.lime(options_route)));
      alert("please copy file", TRM.lime('coffeenode-monitor/monitor-options.json'));
      alert("to", TRM.lime(home));
      alert("and edit it to match your needs");
      log();
      process.exit();
    } else {
      throw error;
    }
  }


  /* Preprocess settings: */

  if (O['watch-routes'] == null) {
    O['watch-routes'] = [home];
  }

  if (O['start'] == null) {
    O['start'] = './lib/start.js';
  }


  /* Report settings: */

  log();

  for (name in O) {
    value = O[name];
    log(TRM.grey('setting'), TRM.gold("" + name + ":"), TRM.lime(rpr(value)));
  }

  start = function() {
    if ((O['on-change'] != null) && O['on-change'].length > 0) {
      info("executing " + (rpr(O['on-change'])));
      njs_cp.exec(O['on-change'], function(error, stdout, stderr) {
        var line, _i, _len, _ref;
        if (error != null) {
          throw error;
        }
        if ((stderr != null) && stderr.length !== 0) {
          throw new Error(stderr);
        }
        _ref = stdout.split('\n');
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          line = _ref[_i];
          if (line.length !== 0) {
            info(line);
          }
        }
        return _start();
      });
    } else {
      _start();
    }
    return null;
  };

  _start = function() {

    /* TAINT: module-global state */
    var arity, command, parameters, start_command;
    _restart_on_exit = false;

    /* TAINT: ad-hoc parsing isn't very safety-proof: */
    start_command = O['start'].split(/[ ]+/);
    switch (arity = start_command.length) {
      case 0:
        throw new Error("unable to parse start command: " + (rpr(O['start'])));
        break;
      case 1:
        command = start_command[0];
        parameters = [];
        break;
      default:
        command = start_command.shift();
        parameters = start_command;
    }
    info('command:   ', rpr(command));
    info('parameters:', rpr(parameters));
    server = njs_cp.fork(command, parameters);
    server.on('error', function(error) {
      return alert(error);
    });
    server.on('close', function(code, signal) {
      server_is_running = false;
      if (code != null) {
        warn("process with PID " + server['pid'] + " received signal #" + code);
      }
      if (_restart_on_exit) {
        return start();
      } else {
        return help("process will be restarted on code change");
      }
    });
    return server_is_running = true;
  };

  stop_server = function(restart_on_exit) {
    if (restart_on_exit == null) {
      restart_on_exit = false;
    }

    /* TAINT: module-global state */
    _restart_on_exit = restart_on_exit;
    if (server_is_running) {
      info("stopping process with PID " + server.pid);
      return server.kill('SIGTERM');
    } else {
      return server.emit('close');
    }
  };

  restart_server = function() {
    return stop_server(true);
  };


  /* TAINT we need a solution for this: */

  watchr_options = {
    paths: O['watch-routes'],

    /* TAINT: experimental, must go to options */
    ignoreCustomPatterns: /(\.js|\.css)$/,
    listeners: {
      error: function(error) {
        return log(TRM.red("an error occured:", error));
      },
      change: function(type, route, current_stat, previous_stat) {
        info("change:", route);
        return restart_server();
      },
      watching: function(error, watchers) {
        var filename, watcher, _ref, _results;
        if (error != null) {
          throw error;
        }
        log();
        _ref = watchers['children'];
        _results = [];
        for (filename in _ref) {
          watcher = _ref[filename];
          _results.push(whisper("watching " + watcher['path']));
        }
        return _results;
      }
    }
  };

  watchr.watch(watchr_options);

  start();

}).call(this);
/****generated by https://github.com/loveencounterflow/larq****/