from datetime import datetime, timedelta
import csv
class Tweet:
    def __init__(self, content, date):
        self.Content = content
        self.Date = date

class BitcoinTransaction:
    def __init__(self, date, closeprice, volumeBTC, volumeUSD, tradecount):
        self.Date = date
        self.Closeprice = closeprice
        self.VolumeBTC = volumeBTC
        self.VolumeUSD = volumeUSD
        self.Tradecount = tradecount


#Bitcoin transactions import

desiredSymbols = ["AM", "PM"]
BitcoinFile = "Binance_Bitcoinbyhour.csv"
transactions = [] #this is a list of all bitcoin transactions

isDateUnsupported = False #True

with open(BitcoinFile, newline="\n") as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        dateString = row["date"]
        for desiredSymbol in desiredSymbols:
            if desiredSymbol in dateString:
                isDateUnsupported = True
        if isDateUnsupported == True:
            isDateUnsupported = False
            continue   
        date = datetime.strptime(row["date"], "%m/%d/%y %H:%M")
        closeprice = float(row["close"])
        volumeBTC = float(row["Volume BTC"])
        volumeUSD = float(row["Volume USDT"])
        tradecount = int(row["tradecount"])
        transaction = BitcoinTransaction(date, closeprice, volumeBTC, volumeUSD, tradecount)
        transactions.append(transaction)


# tweets import

file = "file.csv"
tweets = [] #this is a list of tweets

with open(file, newline="\n") as csvfile:
    reader = csv.DictReader(csvfile) #including all row values separated by comma
    for row in reader:
        text = row["Text"]
        date = datetime.strptime(row["UTC"], "%Y-%m-%dT%H:%M:%S.%fZ")
        tweet = Tweet(text, date)
        tweets.append(tweet)

# tweet filter with desired words
desiredWords = ["bitcoin", "btc", "crypto", "currency"]

tweetsWithBitcoin = []

for tweet in tweets:
    for desiredWord in desiredWords:
        if desiredWord in tweet.Content.lower():
            tweetsWithBitcoin.append(tweet)

# tweetsWithBitcoin = sorted(tweetsWithBitcoin, key=tweet.Content)
# check significant tweets

hourAdded = timedelta(hours=24)

priceBeforeTweet = 0
priceAfterTweet = 0

priceDifferent = 0

countTransactionBefore = 0
countTransactionAfter = 0

with open('CryptoTweetsElonMusk.csv', 'w', encoding='UTF8') as f:
    writer = csv.writer(f)

    headers = ['Tweet Content', 'Tweet Time', 'Price 24 hours Before Tweet', 'Price 24 hours after tweet', 'Price different']
    writer.writerow(headers)

    # print('Tweet Content', 'Tweet Time', 'Price 24 hours Before Tweet', 'Price 24 hours after tweet', 'Price different',sep='\\')
    for tweet in tweetsWithBitcoin:
        for transaction in transactions:
            if ((transaction.Date >= (tweet.Date - hourAdded)) & (transaction.Date <= tweet.Date)):
                priceBeforeTweet += transaction.Closeprice
                countTransactionBefore += 1
            if ((transaction.Date >= tweet.Date) & (transaction.Date <= (tweet.Date + hourAdded))):
                priceAfterTweet += transaction.Closeprice
                countTransactionAfter += 1
        priceBeforeTweet /= countTransactionBefore
        priceAfterTweet /= countTransactionAfter
        priceDifferent = priceAfterTweet - priceBeforeTweet

        csvRow = [tweet.Content, tweet.Date, priceBeforeTweet, priceAfterTweet, priceDifferent]
        writer.writerow(csvRow)

        # print(tweet.Content, tweet.Date, priceBeforeTweet, priceAfterTweet, priceDifferent, sep='\\')