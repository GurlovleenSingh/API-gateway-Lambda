# This Python code will be responsible for handling user registration:
import json

def lambda_handler(event, context):
    # Extract user data from the request
    user_data = json.loads(event['body'])
    username = user_data.get('username')
    email = user_data.get('email')

    # Here you would typically save the user data to a database
    # For this example, we'll just return a success message

    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': f'User {username} registered successfully!',
            'email': email
        })
    }
