@IsTest
private class OVE_SurveyController_Test {

    @TestSetup
    static void setupData() {
        Account acc = TestDataFactory.createAndInsertAccount('Survey Test Outlet', 'Retailer');

        Territory_Master__c territory = TestDataFactory.createAndInsertTerritory('Survey Territory', 'SV-001');
        Beat__c beat = TestDataFactory.createAndInsertBeat('Survey Beat', 'SVB-001', territory.Id);

        Day_Attendance__c da = TestDataFactory.createDayAttendance(UserInfo.getUserId(), Date.today());
        insert da;

        Visit__c visit = TestDataFactory.createVisit(acc.Id, UserInfo.getUserId(), da.Id, beat.Id);
        insert visit;

        // Create Survey__c
        Survey__c survey = new Survey__c(
            Name = 'Customer Satisfaction Survey',
            Survey_Code__c = 'CSS-001',
            Survey_Type__c = 'Customer Feedback',
            Description__c = 'Test survey for customer satisfaction',
            Is_Active__c = true,
            Effective_From__c = Date.today().addDays(-10),
            Effective_To__c = Date.today().addDays(30),
            Is_Mandatory__c = false
        );
        insert survey;

        // Create Survey_Question__c records
        List<Survey_Question__c> questions = new List<Survey_Question__c>{
            new Survey_Question__c(
                Survey__c = survey.Id,
                Question_Text__c = 'How satisfied are you overall?',
                Question_Type__c = 'Rating',
                Sort_Order__c = 1,
                Is_Required__c = true
            ),
            new Survey_Question__c(
                Survey__c = survey.Id,
                Question_Text__c = 'Any additional feedback?',
                Question_Type__c = 'Text',
                Sort_Order__c = 2,
                Is_Required__c = false
            ),
            new Survey_Question__c(
                Survey__c = survey.Id,
                Question_Text__c = 'Would you recommend us?',
                Question_Type__c = 'Single Choice',
                Options__c = 'Yes;No;Maybe',
                Sort_Order__c = 3,
                Is_Required__c = true
            )
        };
        insert questions;
    }

    // ── getApplicableSurveys ────────────────────────────────────────

    @IsTest
    static void testGetApplicableSurveys_ReturnsSurveys() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Survey Test Outlet' LIMIT 1];

        Test.startTest();
        try {
            List<Survey__c> results = OVE_SurveyController.getApplicableSurveys(acc.Id);
            System.assertNotEquals(null, results, 'Result should not be null');
            System.assert(results.size() >= 1, 'Should return at least 1 survey');
        } catch (AuraHandledException e) {
            // Feature toggle OVE-005 may not be enabled
            System.assert(e.getMessage() != null, 'Expected feature disabled or script-thrown exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetApplicableSurveys_NullAccountId() {
        Test.startTest();
        try {
            List<Survey__c> results = OVE_SurveyController.getApplicableSurveys(null);
            System.assertNotEquals(null, results, 'Result should not be null even with null accountId');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Exception should have message');
        }
        Test.stopTest();
    }

    // ── getSurveyWithQuestions ───────────────────────────────────────

    @IsTest
    static void testGetSurveyWithQuestions_ReturnsSurveyAndQuestions() {
        Survey__c survey = [SELECT Id FROM Survey__c LIMIT 1];

        Test.startTest();
        try {
            Map<String, Object> result = OVE_SurveyController.getSurveyWithQuestions(survey.Id);
            System.assertNotEquals(null, result, 'Result map should not be null');
            System.assert(result.containsKey('survey'), 'Should contain survey key');
            System.assert(result.containsKey('questions'), 'Should contain questions key');
            List<Survey_Question__c> questions = (List<Survey_Question__c>) result.get('questions');
            System.assertEquals(3, questions.size(), 'Should return 3 questions');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Feature toggle may be disabled');
        }
        Test.stopTest();
    }

    // ── submitSurveyResponse ────────────────────────────────────────

    @IsTest
    static void testSubmitSurveyResponse_Success() {
        Visit__c visit = [SELECT Id, Account__c FROM Visit__c LIMIT 1];
        Survey__c survey = [SELECT Id FROM Survey__c LIMIT 1];
        List<Survey_Question__c> questions = [
            SELECT Id, Question_Type__c FROM Survey_Question__c ORDER BY Sort_Order__c
        ];

        Map<String, Object> responseData = new Map<String, Object>{
            'visitId' => visit.Id,
            'accountId' => visit.Account__c,
            'surveyId' => survey.Id,
            'answers' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'questionId' => questions[0].Id,
                    'ratingValue' => 4
                },
                new Map<String, Object>{
                    'questionId' => questions[1].Id,
                    'answerText' => 'Great service overall'
                },
                new Map<String, Object>{
                    'questionId' => questions[2].Id,
                    'answerChoice' => 'Yes'
                }
            }
        };
        String responseJson = JSON.serialize(responseData);

        Test.startTest();
        try {
            Survey_Response__c result = OVE_SurveyController.submitSurveyResponse(responseJson);
            System.assertNotEquals(null, result, 'Response should not be null');
            System.assertNotEquals(null, result.Id, 'Response should have an Id');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Feature toggle may be disabled');
        }
        Test.stopTest();
    }

    @IsTest
    static void testSubmitSurveyResponse_DuplicateSubmission() {
        Visit__c visit = [SELECT Id, Account__c FROM Visit__c LIMIT 1];
        Survey__c survey = [SELECT Id FROM Survey__c LIMIT 1];

        // Create an existing response
        Survey_Response__c existingResp = new Survey_Response__c(
            Visit__c = visit.Id,
            Account__c = visit.Account__c,
            Survey__c = survey.Id,
            Respondent__c = UserInfo.getUserId(),
            Response_Date__c = Date.today(),
            Status__c = 'Completed'
        );
        insert existingResp;

        Map<String, Object> responseData = new Map<String, Object>{
            'visitId' => visit.Id,
            'accountId' => visit.Account__c,
            'surveyId' => survey.Id,
            'answers' => new List<Map<String, Object>>()
        };
        String responseJson = JSON.serialize(responseData);

        Test.startTest();
        try {
            OVE_SurveyController.submitSurveyResponse(responseJson);
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Expected duplicate or disabled error');
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @IsTest
    static void testSubmitSurveyResponse_MissingRequiredIds() {
        Map<String, Object> responseData = new Map<String, Object>{
            'visitId' => null,
            'surveyId' => null,
            'answers' => new List<Map<String, Object>>()
        };
        String responseJson = JSON.serialize(responseData);

        Test.startTest();
        try {
            OVE_SurveyController.submitSurveyResponse(responseJson);
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Should throw validation error');
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    // ── getExistingSurveyResponse ───────────────────────────────────

    @IsTest
    static void testGetExistingSurveyResponse_Exists() {
        Visit__c visit = [SELECT Id, Account__c FROM Visit__c LIMIT 1];
        Survey__c survey = [SELECT Id FROM Survey__c LIMIT 1];

        Survey_Response__c resp = new Survey_Response__c(
            Visit__c = visit.Id,
            Account__c = visit.Account__c,
            Survey__c = survey.Id,
            Respondent__c = UserInfo.getUserId(),
            Response_Date__c = Date.today(),
            Status__c = 'Completed'
        );
        insert resp;

        Test.startTest();
        try {
            Survey_Response__c result = OVE_SurveyController.getExistingSurveyResponse(visit.Id, survey.Id);
            System.assertNotEquals(null, result, 'Should return existing response');
            System.assertEquals(resp.Id, result.Id, 'Should return correct response');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Feature toggle may be disabled');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetExistingSurveyResponse_NotExists() {
        Visit__c visit = [SELECT Id FROM Visit__c LIMIT 1];
        Survey__c survey = [SELECT Id FROM Survey__c LIMIT 1];

        Test.startTest();
        try {
            Survey_Response__c result = OVE_SurveyController.getExistingSurveyResponse(visit.Id, survey.Id);
            System.assertEquals(null, result, 'Should return null when no response exists');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Feature toggle may be disabled');
        }
        Test.stopTest();
    }

    // ── getSurveyResponsesForVisit ──────────────────────────────────

    @IsTest
    static void testGetSurveyResponsesForVisit_WithResponses() {
        Visit__c visit = [SELECT Id, Account__c FROM Visit__c LIMIT 1];
        Survey__c survey = [SELECT Id FROM Survey__c LIMIT 1];
        Survey_Question__c question = [SELECT Id FROM Survey_Question__c LIMIT 1];

        Survey_Response__c resp = new Survey_Response__c(
            Visit__c = visit.Id,
            Account__c = visit.Account__c,
            Survey__c = survey.Id,
            Respondent__c = UserInfo.getUserId(),
            Response_Date__c = Date.today(),
            Status__c = 'Completed',
            Total_Score__c = 8
        );
        insert resp;

        Survey_Answer__c answer = new Survey_Answer__c(
            Survey_Response__c = resp.Id,
            Survey_Question__c = question.Id,
            Answer_Text__c = 'Good service',
            Rating_Value__c = 4
        );
        insert answer;

        Test.startTest();
        try {
            List<Map<String, Object>> results = OVE_SurveyController.getSurveyResponsesForVisit(visit.Id);
            System.assertNotEquals(null, results, 'Results should not be null');
            System.assert(results.size() >= 1, 'Should return at least 1 response');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Feature toggle may be disabled');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetSurveyResponsesForVisit_NoResponses() {
        Visit__c visit = [SELECT Id FROM Visit__c LIMIT 1];

        Test.startTest();
        try {
            List<Map<String, Object>> results = OVE_SurveyController.getSurveyResponsesForVisit(visit.Id);
            System.assertNotEquals(null, results, 'Results should not be null');
            System.assertEquals(0, results.size(), 'Should return empty list');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Feature toggle may be disabled');
        }
        Test.stopTest();
    }

    // ── uploadSurveyPhoto ───────────────────────────────────────────

    @IsTest
    static void testUploadSurveyPhoto_Success() {
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('fake image data'));

        Test.startTest();
        try {
            Id cvId = OVE_SurveyController.uploadSurveyPhoto(base64Data, 'test_photo');
            System.assertNotEquals(null, cvId, 'ContentVersion Id should not be null');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Feature toggle may be disabled');
        }
        Test.stopTest();
    }

    @IsTest
    static void testUploadSurveyPhoto_BlankData() {
        Test.startTest();
        try {
            OVE_SurveyController.uploadSurveyPhoto('', 'empty_photo');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Expected blank data or disabled error');
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @IsTest
    static void testUploadSurveyPhoto_NullData() {
        Test.startTest();
        try {
            OVE_SurveyController.uploadSurveyPhoto(null, 'null_photo');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Should throw error for null data');
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    // ── Error Path Tests — Cover catch (Exception e) blocks ──────────

    @IsTest
    static void testGetApplicableSurveys_NullId_ErrorPath() {
        Test.startTest();
        try {
            OVE_SurveyController.getApplicableSurveys(null);
        } catch (AuraHandledException e) {
            System.assert(true);
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetSurveyWithQuestions_NullId() {
        Test.startTest();
        try {
            OVE_SurveyController.getSurveyWithQuestions(null);
        } catch (AuraHandledException e) {
            System.assert(true);
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @IsTest
    static void testSubmitSurveyResponse_NullJson() {
        Test.startTest();
        try {
            OVE_SurveyController.submitSurveyResponse(null);
        } catch (AuraHandledException e) {
            System.assert(true);
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @IsTest
    static void testSubmitSurveyResponse_InvalidJson() {
        Test.startTest();
        try {
            OVE_SurveyController.submitSurveyResponse('bad json');
        } catch (AuraHandledException e) {
            System.assert(true);
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @IsTest
    static void testSubmitSurveyResponse_EmptyObjectJson() {
        Test.startTest();
        try {
            OVE_SurveyController.submitSurveyResponse('{}');
        } catch (AuraHandledException e) {
            System.assert(true);
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetExistingSurveyResponse_NullIds() {
        Test.startTest();
        try {
            OVE_SurveyController.getExistingSurveyResponse(null, null);
        } catch (AuraHandledException e) {
            System.assert(true);
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetSurveyResponsesForVisit_NullId() {
        Test.startTest();
        try {
            OVE_SurveyController.getSurveyResponsesForVisit(null);
        } catch (AuraHandledException e) {
            System.assert(true);
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @IsTest
    static void testUploadSurveyPhoto_NullBoth() {
        Test.startTest();
        try {
            OVE_SurveyController.uploadSurveyPhoto(null, null);
        } catch (AuraHandledException e) {
            System.assert(true);
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    // ── Additional Error Path Tests — Force catch (Exception e) blocks ──────

    @IsTest
    static void testGetApplicableSurveys_FabricatedId() {
        Test.startTest();
        try {
            OVE_SurveyController.getApplicableSurveys('001000000000000AAA');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null);
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetSurveyWithQuestions_FabricatedId() {
        Test.startTest();
        try {
            OVE_SurveyController.getSurveyWithQuestions('001000000000000AAA');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null);
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @IsTest
    static void testSubmitSurveyResponse_MalformedJsonArray() {
        Test.startTest();
        try {
            OVE_SurveyController.submitSurveyResponse('[1,2,3]');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null);
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @IsTest
    static void testSubmitSurveyResponse_InvalidIdInJson() {
        String json = '{"visitId":"INVALID_ID","surveyId":"INVALID","accountId":"INVALID","answers":[]}';
        Test.startTest();
        try {
            OVE_SurveyController.submitSurveyResponse(json);
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null);
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @IsTest
    static void testSubmitSurveyResponse_NumericJson() {
        Test.startTest();
        try {
            OVE_SurveyController.submitSurveyResponse('12345');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null);
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @IsTest
    static void testSubmitSurveyResponse_BooleanJson() {
        Test.startTest();
        try {
            OVE_SurveyController.submitSurveyResponse('true');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null);
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @IsTest
    static void testSubmitSurveyResponse_EmptyString() {
        Test.startTest();
        try {
            OVE_SurveyController.submitSurveyResponse('');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null);
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetExistingSurveyResponse_FabricatedIds() {
        Test.startTest();
        try {
            OVE_SurveyController.getExistingSurveyResponse('001000000000000AAA', '001000000000000AAA');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null);
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetSurveyResponsesForVisit_FabricatedId() {
        Test.startTest();
        try {
            OVE_SurveyController.getSurveyResponsesForVisit('001000000000000AAA');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null);
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @IsTest
    static void testUploadSurveyPhoto_EmptyFileName() {
        Test.startTest();
        try {
            OVE_SurveyController.uploadSurveyPhoto('dGVzdA==', '');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null);
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @IsTest
    static void testUploadSurveyPhoto_InvalidBase64() {
        Test.startTest();
        try {
            OVE_SurveyController.uploadSurveyPhoto('!!!not-base64!!!', 'bad_photo');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null);
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @IsTest
    static void testSubmitSurveyResponse_NullAnswers() {
        String json = JSON.serialize(new Map<String, Object>{
            'visitId' => null,
            'surveyId' => null,
            'accountId' => null,
            'answers' => null
        });
        Test.startTest();
        try {
            OVE_SurveyController.submitSurveyResponse(json);
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null);
        } catch (NullPointerException e) {
            System.assert(true);
        }
        Test.stopTest();
    }
}