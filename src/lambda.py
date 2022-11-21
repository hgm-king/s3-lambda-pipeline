import pandas

def lambda_handler(event, context):
    print(event)
    print(context)
    return { 
        "message" : event,
    }