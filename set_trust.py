import requests
import sys
import json
from pathlib import Path
import urllib.request

external_ip = urllib.request.urlopen('https://ident.me').read().decode('utf8')

NODE_URL = 'http://'+external_ip+':8456'

res = Path('/root/newrl/data_mainnet/.auth.json').read_text()
WALLET = json.loads(res)

TRUST_SCORE_DECIMAL = 10000

destination_wallet_address = sys.argv[1]
source_wallet_address = WALLET['address']
score = sys.argv[2]
score = int(score)


trust_score_update_request = {
      "source_address": source_wallet_address,
      "destination_address": destination_wallet_address,
      "tscore": score * TRUST_SCORE_DECIMAL
  }
response = requests.post(NODE_URL + '/update-trustscore', json=trust_score_update_request)
unsigned_transaction = response.json()
unsigned_transaction['transaction']['fee'] = 1000000

# In production use Newrl sdk to sign offline
response = requests.post(NODE_URL + '/sign-transaction', json={
    "wallet_data": WALLET,
    "transaction_data": unsigned_transaction
})

signed_transaction = response.json()

print('signed_transaction', signed_transaction)
response = requests.post(NODE_URL + '/validate-transaction', json=signed_transaction)
print(response.text)
print(response.status_code)
assert response.status_code == 200
