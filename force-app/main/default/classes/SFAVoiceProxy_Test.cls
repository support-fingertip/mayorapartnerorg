/**
 * Coverage + contract tests for SFAVoiceProxy. Uses HttpCalloutMock so no
 * real callout happens. Verifies the three entry points map the backend
 * envelope correctly and that failures degrade to isSuccess=false (never throw).
 */
@IsTest
private class SFAVoiceProxy_Test {

    private class VoiceMock implements HttpCalloutMock {
        private Integer code;
        private String  bodyJson;
        VoiceMock(Integer code, String bodyJson) {
            this.code = code;
            this.bodyJson = bodyJson;
        }
        public HttpResponse respond(HttpRequest req) {
            // sanity: the proxy must set a bearer JWT + JSON content type
            System.assert(req.getHeader('Authorization').startsWith('Bearer '),
                'proxy must send a bearer JWT');
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(code);
            res.setBody(bodyJson);
            return res;
        }
    }

    private static final String CATALOG =
        '[{"id":"p1","name":"Sunflower Oil","price":100,"min_order_qty":6}]';
    private static final String CART = '[{"product_id":"p1","qty":6}]';

    @IsTest
    static void processVoice_ok() {
        String body = JSON.serialize(new Map<String, Object>{
            'ok' => true,
            'transcript' => 'add six sunflower oil',
            'spoken_reply' => 'Added 6 Sunflower Oil.',
            'operations' => new List<Object>{
                new Map<String, Object>{
                    'action' => 'add', 'product_query' => 'sunflower oil',
                    'quantity' => 6, 'resolved_product_ids' => new List<String>{'p1'}
                }
            }
        });
        Test.setMock(HttpCalloutMock.class, new VoiceMock(200, body));

        Test.startTest();
        SFAVoiceProxy.VoiceProcessResult r = SFAVoiceProxy.processVoice(
            'AAAA', 'audio/webm', 'en', CATALOG, CART, 5000, 500, null
        );
        Test.stopTest();

        System.assert(r.isSuccess, 'expected success');
        System.assertEquals('add six sunflower oil', r.transcript);
        System.assert(r.operationsJson.contains('p1'), 'operations passed through');
    }

    @IsTest
    static void processVoice_blankAudio_failsClean() {
        SFAVoiceProxy.VoiceProcessResult r = SFAVoiceProxy.processVoice(
            '', 'audio/webm', 'en', CATALOG, CART, null, 500, null
        );
        System.assert(!r.isSuccess);
        System.assertNotEquals(null, r.errorMessage);
    }

    @IsTest
    static void processVoice_backendError_failsClean() {
        Test.setMock(HttpCalloutMock.class, new VoiceMock(500, '{"ok":false,"error":"boom"}'));
        Test.startTest();
        SFAVoiceProxy.VoiceProcessResult r = SFAVoiceProxy.processVoice(
            'AAAA', 'audio/webm', 'en', CATALOG, CART, null, 500, 'p1'
        );
        Test.stopTest();
        System.assert(!r.isSuccess, 'non-2xx must fail clean');
        System.assertNotEquals(null, r.errorMessage);
    }

    @IsTest
    static void realtimeSession_ok() {
        String body = JSON.serialize(new Map<String, Object>{
            'ok' => true,
            'client_secret' => 'ek_test_123',
            'expires_at' => 1900000000,
            'model' => 'gpt-realtime',
            'voice' => 'alloy',
            'session_config' => new Map<String, Object>{ 'type' => 'realtime' }
        });
        Test.setMock(HttpCalloutMock.class, new VoiceMock(200, body));

        Test.startTest();
        SFAVoiceProxy.RealtimeSessionResult r = SFAVoiceProxy.realtimeSession(
            'Sri Outlet', CATALOG, CART, 5000, 500, 'alloy'
        );
        Test.stopTest();

        System.assert(r.isSuccess);
        System.assertEquals('ek_test_123', r.clientSecret);
        System.assertEquals('gpt-realtime', r.model);
        System.assert(r.sessionConfig.contains('realtime'));
    }

    @IsTest
    static void realtimeSession_noSecret_failsClean() {
        Test.setMock(HttpCalloutMock.class, new VoiceMock(200, '{"ok":false,"error":"nope"}'));
        Test.startTest();
        SFAVoiceProxy.RealtimeSessionResult r = SFAVoiceProxy.realtimeSession(
            null, CATALOG, CART, null, 500, null
        );
        Test.stopTest();
        System.assert(!r.isSuccess);
        System.assertEquals('nope', r.errorMessage);
    }

    @IsTest
    static void speak_ok() {
        Test.setMock(HttpCalloutMock.class,
            new VoiceMock(200, '{"ok":true,"audio_base64":"QUJD","content_type":"audio/mpeg"}'));
        Test.startTest();
        SFAVoiceProxy.SpeakResult s = SFAVoiceProxy.speak('Added six sunflower oil');
        Test.stopTest();
        System.assert(s.isSuccess);
        System.assertEquals('QUJD', s.audioBase64);
        System.assertEquals('audio/mpeg', s.contentType);
    }

    @IsTest
    static void speak_blank_failsClean() {
        SFAVoiceProxy.SpeakResult s = SFAVoiceProxy.speak('');
        System.assert(!s.isSuccess);
    }

    @IsTest
    static void sarvamLiveToken_ok() {
        // No callout — just mints the JWT (mocked to 'test.jwt.token' in tests)
        // and returns the wss endpoint URL for the browser to open.
        Test.startTest();
        SFAVoiceProxy.SarvamLiveTokenResult r = SFAVoiceProxy.sarvamLiveToken();
        Test.stopTest();
        System.assert(r.isSuccess, 'token should mint');
        System.assertEquals('test.jwt.token', r.token);
        System.assert(r.wsUrl.startsWith('wss://'), 'wss url returned');
        System.assert(r.wsUrl.endsWith('/sfa/voice/sarvam-live'), 'correct path');
    }
}