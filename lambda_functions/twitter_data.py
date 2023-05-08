import tweepy as tw
import logging
from botocore.exceptions import ClientError
import boto3


logger = logging.getLogger(__name__)


consumer_key = ""
consumer_secret = ""
access_token = ""
access_token_secret = ""

#Authentication to Twitter API
auth = tw.OAuthHandler(consumer_key, consumer_secret)
auth.set_access_token(access_token, access_token_secret)
api = tw.API(auth, wait_on_rate_limit=True)

search_query = "#covid19 -filter:retweets"

data = []

def lambda_handler(event, context):

    tweets = tw.Cursor(api.search_tweets,
                q=search_query,
                lang="en",
                since="2022-12-12",
                until="2023-04-20").items(50)

    for tweet in tweets:
        print(tweet.created_at)
        put_record(data=tweet.text)
        logger.info('This is the tweet:', data)


def put_record(data):

    kinesis_client = boto3.client('firehose', region_name='us-east-1')
    name = 'kinesis-firehose'

    try:
        response = kinesis_client.put_record(
            DeliveryStreamName=name,
            Record={
                'Data': data }
                )
        print(response)
        logger.info("Put record in stream %s.", name)
    except ClientError:
        logger.exception("Couldn't put record in stream %s.", name)
        raise
    else:
        return response




