import requests, json
import unittest
import sys
from awsauth import S3Auth
from datetime import datetime

class UserRestAPITests(unittest.TestCase):
    ACCESS_KEY='test'
    SECRET_KEY='test'
    URL='http://127.0.0.1:7480'

    def setUp(self):
        self.auth = S3Auth(UserRestAPITests.ACCESS_KEY, UserRestAPITests.SECRET_KEY, self.URL)

    def test_smoke_test(self):
        dt = datetime.now()
        ts = datetime.timestamp(dt)
        bucket_name = "foo." + str(ts)

        # add a bucket and check the json response for a system user
        response = requests.put(self.URL + "/" + bucket_name, auth=self.auth)
        self.assertEqual(200, response.status_code)
        json_response = json.loads(response.content)
        self.assertIsInstance(json_response, dict)
        self.assertIsInstance(json_response["bucket_info"], dict)
        self.assertIsInstance(json_response["bucket_info"]["bucket"], dict)
        self.assertNotEqual("", json_response["bucket_info"]["bucket"]["bucket_id"])
        self.assertEqual(json_response["bucket_info"]["bucket"]["bucket_id"], json_response["bucket_info"]["bucket"]["marker"])
        self.assertEqual(bucket_name, json_response["bucket_info"]["bucket"]["name"])
        self.assertNotEqual("", json_response["bucket_info"]["creation_time"])

if __name__ == "__main__":
    if len(sys.argv) == 2:
        address_port = sys.argv.pop()
        UserRestAPITests.URL = 'http://{0}'.format(address_port)
        unittest.main()
    else:
        print ("usage: {0} ADDRESS:PORT".format(sys.argv[0]))
