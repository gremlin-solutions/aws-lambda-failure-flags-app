import os
import logging
import json
import time
from failureflags import FailureFlag 
from aws_xray_sdk.core import xray_recorder, patch_all

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Automatically instrument supported libraries with AWS X-Ray.
patch_all()

def handler(event, context):
    now = time.gmtime()           # Capture current GMT time for a timestamp.
    start = time.time()           # Record start time for processing.

    # Invoke a Gremlin Failure Flag for demonstration.
    active, impacted, experiments = FailureFlag(
            "http-ingress",  # Name of the failure flag.
            {},              # Dict of labels with dynamic invocation context
            debug=True       # Debug mode enabled.
        ).invoke()

    end = time.time()             # Record end time after processing.
    
    # Return a JSON response with processing time and failure flag data.
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json'
        },
        'body': json.dumps({
            'processingTime': round((end * 1000) - (start * 1000)),  # Milliseconds.
            'isActive': active,
            'isImpacted': impacted,
            'timestamp': time.strftime('%Y-%m-%dT%H:%M:%S', now)
        }, sort_keys=True, indent=2)
    }

