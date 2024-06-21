bring cloud;
bring http;

pub struct DiscordProps {
  token: cloud.Secret;
}

pub struct DiscordPostMessageOptions {
  channel: str;
  text: str;
}

pub class DiscordClient {
  token: cloud.Secret;

  new(props: DiscordProps) {
    this.token = props.token;
  }

  pub inflight sendMessage(args: DiscordPostMessageOptions) {
    let token = this.token.value();

    // API documentation: https://discord.com/developers/docs/resources/channel#create-message
    let endpoint = "https://discord.com/api/v10/channels/{args.channel}/messages";
    let res = http.fetch(endpoint, {
      method: http.HttpMethod.POST,
      headers: {
        Authorization: "Bot {token}",
        "Content-Type": "application/json; charset=UTF-8",
        "User-Agent": "DiscordBot (https://github.com/Chriscbr/wing-releases-discord-bot, 0.0.1)",
      },
      body: Json.stringify({
        content: args.text,
        // suppress embeds
        flags: 4, // 1 << 2
      }),
    });

    log(Json.stringify(res));
  }  
}
