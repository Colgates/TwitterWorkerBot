![Twitter Worker Telegram Bot](img/image.webp)

# TwitterWorkerBot

Hobby project to get tweets from Tweeter and post it to the channel in Telegram  

Written with:
- Swift
- VAPOR
- Telegram Vapor Bot, thanks to Oleh Hudeichuk for the library ([Telegram Vapor Bot](https://github.com/nerzh/telegram-vapor-bot)).
- PostgreSQL
 
### Installing requirements
- `BOT_TOKEN`: The Telegram Bot Token that you got from [@BotFather](https://t.me/BotFather). `Str`
- `BEARER_TOKEN`: The Tweeter API bearer token `Str`
- `DB_URL`: Url for your PostgreSQL Database `Str`
- `CHAT_ID`: ID of public chat in telegram where you want to post these tweets `Int`

### Installation
1. Deploy this repo on any cloud platform that supports Docker containers
2. Deploy PostgreSQL database
3. Enter environment variables

### Commands:
- /add (username)- Add user to database
- /check - Check the state of bot and users in database
- /delete (username)- Delete user from database
- /deleteall - Delete all users from database
- /gettweets - Get the tweets and publish them to the chat
- /refresh - sets newestTweet variables to nil, so you can post last tweets again

### ToDos:
1. Implement a scheduler, for now you can fetch new tweets manually, by /gettweets command. 
2. Although the bot makes requests to twitter for each user in the list in between and then posts messages at a rate of one message per second, it still throws an error: Too many requests. Trying to figure it out

## Important:
If you decide to deploy your PostgreSQL on render.com and getting an error like: 
"[Code: "28000", Message: "SSL/TLS required", Localized Severity: "FATAL"])))" 

- add to your DB_URL '?ssl=true'
