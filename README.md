# wing-releases-discord-bot

A Discord bot that posts new releases from the Wing repository to the #releases channel on the [Wing Discord server](https://t.winglang.io/discord).
Here are some things its used for:

- Breaking changes - posted as soon as they are released
- Weekly release digests - posted every Sunday with all the changes from the past week

### Development

Prerequisites:

- Node.js
- Wing CLI
- A [discord bot](https://discord.com/developers/docs/quick-start/getting-started)
- Permissions to add webhooks to the Wing and Winglibs repositories

To run the bot locally:

1. Clone the repository
2. Install the dependencies with `npm install`
3. Create a `.env` file with the following content:

```
DISCORD_TOKEN=your_discord_bot_token
```

Make sure the bot has permissions to read and send messages in the #releases channel on the Wing Discord server (or any other channel you want to use).

4. `wing run` to start the bot and open the Wing Console.
5. (untested) To forward GitHub events to the local server, you can run a command like `gh webhook forward --events=releases --repo=monalisa/smile --url="http://localhost:1234/payload"`, passing in the name of the repo you want to forward events for, and the port of the `cloud.Api` endpoint (you can find this by looking for the API resource(s) inside the Wing Console).

### Deployment

Once the app is deployed to your preferred cloud platform, it will expose two endpoints that can be used as webhooks: one for the [Wing repository](https://github.com/winglang/wing) and another for the [Winglibs repository](https://github.com/winglang/winglibs).

1. Go to the repository settings for the Wing repository on GitHub and add a new webhook with the following settings:
   - Payload URL: `https://your_endpoint/payload`
   - Content type: `application/json`

You may need to uncheck the "Disable SSL verification" option if your endpoint uses HTTPS.

2. Repeat the same process for the Winglibs repository.

Feel free to hack and remix the code here to suite your own needs. If you have any questions, feel free to ask in the #dev channel on the [Wing Discord server](https://t.winglang.io/discord).
