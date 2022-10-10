import requests, json
import unittest
import sys
from awsauth import S3Auth

class UserRestAPITests(unittest.TestCase):
    ACCESS_KEY='test'
    SECRET_KEY='test'
    URL='http://127.0.0.1:7480'

    def setUp(self):
        self.auth = S3Auth(UserRestAPITests.ACCESS_KEY, UserRestAPITests.SECRET_KEY, self.URL)

    def test_smoke_test(self):
        # list users using the metadata endpoint.
        response = requests.get(self.URL + '/admin/metadata/user', auth=self.auth)
        self.assertEqual(200, response.status_code)
        json_response = json.loads(response.content)
        self.assertIsInstance(json_response, list)
        self.assertIn("testid", json_response)

        # list users (we should get only testid (user created at startup))
        response = requests.get(self.URL + '/admin/user?list', auth=self.auth)
        self.assertEqual(200, response.status_code)
        json_response = json.loads(response.content)
        self.assertIsInstance(json_response, dict)
        self.assertIsInstance(json_response["keys"], list)
        self.assertEqual(1, len(json_response["keys"]))
        self.assertIn("testid", json_response["keys"])

        # add a user
        response = requests.put(self.URL + '/admin/user?uid=user2&display-name=TEST+NAME', auth=self.auth)
        self.assertEqual(200, response.status_code)
        json_response = json.loads(response.content)
        self.assertEqual("user2", json_response["user_id"])
        self.assertEqual("TEST NAME", json_response["display_name"])
        keys = json_response["keys"]
        self.assertEqual(1, len(keys))
        self.assertEqual("user2", keys[0]["user"])
        self.assertNotEqual("", keys[0]["access_key"])
        self.assertNotEqual("", keys[0]["secret_key"])

        # get info new user
        response = requests.get(self.URL + '/admin/user?uid=user2', auth=self.auth)
        self.assertEqual(200, response.status_code)
        json_response = json.loads(response.content)
        self.assertEqual("user2", json_response["user_id"])
        self.assertEqual("TEST NAME", json_response["display_name"])
        keys = json_response["keys"]
        self.assertEqual(1, len(keys))
        self.assertEqual("user2", keys[0]["user"])
        self.assertNotEqual("", keys[0]["access_key"])
        self.assertNotEqual("", keys[0]["secret_key"])

        # list users (we should get testid and user2)
        response = requests.get(self.URL + '/admin/user?list', auth=self.auth)
        self.assertEqual(200, response.status_code)
        json_response = json.loads(response.content)
        self.assertEqual(2, len(json_response["keys"]))
        self.assertEqual("testid", json_response["keys"][0])
        self.assertEqual("user2", json_response["keys"][1])

        # delete user2
        response = requests.delete(self.URL + '/admin/user?uid=user2', auth=self.auth)
        self.assertEqual(200, response.status_code)

        # list users (we should get only testid)
        response = requests.get(self.URL + '/admin/user?list', auth=self.auth)
        self.assertEqual(200, response.status_code)
        json_response = json.loads(response.content)
        self.assertEqual(1, len(json_response["keys"]))
        self.assertEqual("testid", json_response["keys"][0])

if __name__ == "__main__":
    if len(sys.argv) == 2:
        address_port = sys.argv.pop()
        UserRestAPITests.URL = 'http://{0}'.format(address_port)
        unittest.main()
    else:
        print ("usage: {0} ADDRESS:PORT".format(sys.argv[0]))
