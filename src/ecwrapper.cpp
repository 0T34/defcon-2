// Copyright (c) 2009-2014 The Bitcoin Core developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include "ecwrapper.h"

#include "serialize.h"
#include "uint256.h"

#include <openssl/bn.h>
#include <openssl/ecdsa.h>
#include <openssl/obj_mac.h>

namespace {

class ecgroup_order
{
public:
  static const EC_GROUP* get()
  {
      static const ecgroup_order wrapper;
      return wrapper.pgroup;
  }

private:
  ecgroup_order()
  : pgroup(EC_GROUP_new_by_curve_name(NID_secp256k1))
  {
  }

  ~ecgroup_order()
  {
    EC_GROUP_free(pgroup);
  }

  EC_GROUP* pgroup;
};

} // anon namespace

CECKey::CECKey() {
    pkey = EC_KEY_new();
    assert(pkey != NULL);
    int result = EC_KEY_set_group(pkey, ecgroup_order::get());
    assert(result);
}

CECKey::~CECKey() {
    EC_KEY_free(pkey);
}

void CECKey::GetPubKey(std::vector<unsigned char> &pubkey, bool fCompressed) {
    EC_KEY_set_conv_form(pkey, fCompressed ? POINT_CONVERSION_COMPRESSED : POINT_CONVERSION_UNCOMPRESSED);
    int nSize = i2o_ECPublicKey(pkey, NULL);
    assert(nSize);
    assert(nSize <= 65);
    pubkey.clear();
    pubkey.resize(nSize);
    unsigned char *pbegin(begin_ptr(pubkey));
    int nSize2 = i2o_ECPublicKey(pkey, &pbegin);
    assert(nSize == nSize2);
}

bool CECKey::SetPubKey(const unsigned char* pubkey, size_t size) {
    return o2i_ECPublicKey(&pkey, &pubkey, size) != NULL;
}

bool CECKey::Verify(const uint256 &hash, const std::vector<unsigned char>& vchSig) {
    if (vchSig.empty())
        return false;

    // New versions of OpenSSL will reject non-canonical DER signatures. de/re-serialize first.
    unsigned char *norm_der = NULL;
    ECDSA_SIG *norm_sig = ECDSA_SIG_new();
    const unsigned char* sigptr = &vchSig[0];
    assert(norm_sig);
    if (d2i_ECDSA_SIG(&norm_sig, &sigptr, vchSig.size()) == NULL)
    {
        /* As of OpenSSL 1.0.0p d2i_ECDSA_SIG frees and nulls the pointer on
         * error. But OpenSSL's own use of this function redundantly frees the
         * result. As ECDSA_SIG_free(NULL) is a no-op, and in the absence of a
         * clear contract for the function behaving the same way is more
         * conservative.
         */
        ECDSA_SIG_free(norm_sig);
        return false;
    }
    int derlen = i2d_ECDSA_SIG(norm_sig, &norm_der);
    ECDSA_SIG_free(norm_sig);
    if (derlen <= 0)
        return false;

    // -1 = error, 0 = bad sig, 1 = good
    bool ret = ECDSA_verify(0, (unsigned char*)&hash, sizeof(hash), norm_der, derlen, pkey) == 1;
    OPENSSL_free(norm_der);
    return ret;
}

bool CECKey::TweakPublic(const unsigned char vchTweak[32]) {
    bool ret = true;
    BN_CTX *ctx = BN_CTX_new();
    BN_CTX_start(ctx);
    BIGNUM *bnTweak = BN_CTX_get(ctx);
    BIGNUM *bnOrder = BN_CTX_get(ctx);
    BIGNUM *bnOne = BN_CTX_get(ctx);
    const EC_GROUP *group = EC_KEY_get0_group(pkey);
    EC_GROUP_get_order(group, bnOrder, ctx); // what a grossly inefficient way to get the (constant) group order...
    BN_bin2bn(vchTweak, 32, bnTweak);
    if (BN_cmp(bnTweak, bnOrder) >= 0)
        ret = false; // extremely unlikely
    EC_POINT *point = EC_POINT_dup(EC_KEY_get0_public_key(pkey), group);
    BN_one(bnOne);
    EC_POINT_mul(group, point, bnTweak, point, bnOne, ctx);
    if (EC_POINT_is_at_infinity(group, point))
        ret = false; // ridiculously unlikely
    EC_KEY_set_public_key(pkey, point);
    EC_POINT_free(point);
    BN_CTX_end(ctx);
    BN_CTX_free(ctx);
    return ret;
}

bool CECKey::SanityCheck()
{
    const EC_GROUP *pgroup = ecgroup_order::get();
    if(pgroup == NULL)
        return false;
    // TODO Is there more EC functionality that could be missing?
    return true;
}
