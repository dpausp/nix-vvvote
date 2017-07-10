self: {
  debug = true;
  keydir = null;
  # By default, keys are linked from keydir to the Nix store. Activate the following setting to copy them instead.
  # !!!WARNING: private keys will be world-readable in the Nix store when this is set to true!!!
  copy_keys_to_store = false;
  server_number = 1; # position of this server, starts with 1
  # urls for the backend servers. The first server is pos 1, the second pos 2 and so on.
  backend_urls = [ "http://localhost:10001/" "http://localhost:10002/" ];
  id_server_url = "https://id.localhost";

  tally_server_number = 1; # which server acts as tally server? (starts at 1!)
  vote_port = 10001;
  webclient_port = 10003;
  webclient_url = "http://localhost:${toString self.webclient_port}";
  use_anon_server = true;

  is_tally_server = self.tally_server_number == self.server_number;

  db = {
    name = "vvvote";
    host = "localhost";
    port = "3307";
    user = "vvvote";
    password = "vvvote";
    prefix = "";
  };

  uwsgi = {
    socket_port = 20001;
    socket_address = "127.0.0.1";
    http_port = 10001;
    http_address = "127.0.0.1";
  };

  oauth = {
    server_id = "ekklesia";
    server_description = "ID Server";
    client_ids =  [ "vvvote" "vvvote2" ];
    client_secrets = [ "vvvote" "vvvote2" ];
    endpoints = {
      authorization = self.id_server_url + "/oauth2/authorize/";
      token = self.id_server_url + "/oauth2/token/";
      is_in_voter_list = self.id_server_url + "/api/v1/user/listmember/";
      get_membership = self.id_server_url + "/api/v1/user/membership/";
      get_auid = self.id_server_url + "/api/v1/user/auid/";
      sendmail = self.id_server_url + "/api/v1/user/mails/";
    };
  };
}
