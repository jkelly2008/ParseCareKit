//
//  ParseCareKitTests.swift
//  ParseCareKitTests
//
//  Created by Corey Baker on 9/12/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import XCTest
@testable import ParseCareKit
@testable import CareKitStore
@testable import ParseSwift

struct LoginSignupResponse: ParseUser {
    var objectId: String?
    var createdAt: Date?
    var sessionToken: String
    var updatedAt: Date?
    var ACL: ParseACL?

    // provided by User
    var username: String?
    var email: String?
    var password: String?

    // Your custom keys
    var customKey: String?

    init() {
        self.createdAt = Date()
        self.updatedAt = Date()
        self.objectId = "yarr"
        self.ACL = nil
        self.customKey = "blah"
        self.sessionToken = "myToken"
        self.username = "hello10"
        self.password = "world"
        self.email = "hello@parse.com"
    }
}

func userLogin() {
    let loginResponse = LoginSignupResponse()

    MockURLProtocol.mockRequests { _ in
        do {
            let encoded = try loginResponse.getEncoder(skipKeys: false).encode(loginResponse)
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        } catch {
            return nil
        }
    }
    do {
       _ = try PCKUser.login(username: loginResponse.username!, password: loginResponse.password!)
    } catch {
        XCTFail(error.localizedDescription)
    }
}

func userLoginToRealServer() {
    let loginResponse = LoginSignupResponse()
    do {
        _ = try PCKUser.signup(username: loginResponse.username!, password: loginResponse.password!)
    } catch {
        do {
            _ = try PCKUser.login(username: loginResponse.username!, password: loginResponse.password!)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}

class ParseCareKitTests: XCTestCase {

    private var parse: ParseRemoteSynchronizationManager!
    private var store: OCKStore!
    
    override func setUpWithError() throws {
        guard let url = URL(string: "http://localhost:1337/1") else {
                    XCTFail("Should create valid URL")
                    return
                }
                ParseSwift.initialize(applicationId: "applicationId",
                                      clientKey: "clientKey",
                                      masterKey: "masterKey",
                                      serverURL: url)
        userLogin()
        //userLoginToRealServer()
        do {
        parse = try ParseRemoteSynchronizationManager(uuid: UUID(uuidString: "3B5FD9DA-C278-4582-90DC-101C08E7FC98")!, auto: false)
        } catch {
            print(error.localizedDescription)
        }
        store = OCKStore(name: "SampleAppStore", type: .onDisk, remote: parse)
        parse?.parseRemoteDelegate = self
        
    }

    override func tearDownWithError() throws {
        MockURLProtocol.removeAll()
        try KeychainStore.shared.deleteAll()
        try ParseStorage.shared.deleteAll()
        try store.delete()
    }
    
    func testNote() throws {
        var careKit = OCKNote(author: "myId", title: "hello", content: "world")

        //Objectable
        careKit.uuid = UUID()
        careKit.createdDate = Date().addingTimeInterval(-200)
        careKit.updatedDate = Date().addingTimeInterval(-99)
        careKit.timezone = .current
        careKit.userInfo = ["String": "String"]
        careKit.remoteID = "we"
        careKit.groupIdentifier = "mine"
        careKit.tags = ["one", "two"]
        careKit.schemaVersion = .init(majorVersion: 4)
        careKit.source = "yo"
        careKit.asset = "pic"
        careKit.notes = [careKit]
        
        //Test CareKit -> Parse
        let parse = try Note.copyCareKit(careKit)

        //Special
        XCTAssertEqual(parse.content, careKit.content)
        XCTAssertEqual(parse.title, careKit.title)
        XCTAssertEqual(parse.author, careKit.author)
        
        //Objectable
        XCTAssertEqual(parse.className, "Note")
        XCTAssertEqual(parse.uuid, careKit.uuid)
        XCTAssertNotNil(parse.createdDate)
        XCTAssertNotNil(parse.updatedDate)
        XCTAssertEqual(parse.timezone, careKit.timezone)
        XCTAssertEqual(parse.userInfo, careKit.userInfo)
        XCTAssertEqual(parse.remoteID, careKit.remoteID)
        XCTAssertEqual(parse.source, careKit.source)
        XCTAssertEqual(parse.asset, careKit.asset)
        XCTAssertEqual(parse.schemaVersion, careKit.schemaVersion)
        XCTAssertEqual(parse.groupIdentifier, careKit.groupIdentifier)
        XCTAssertEqual(parse.tags, careKit.tags)
        XCTAssertEqual(parse.notes?.count, 1)
        XCTAssertEqual(parse.notes?.first?.author, "myId")
        XCTAssertEqual(parse.notes?.first?.title, "hello")
        XCTAssertEqual(parse.notes?.first?.content, "world")
        
        //Test Parse -> CareKit
        let parse2 = try parse.convertToCareKit()
        
        //Special
        XCTAssertEqual(parse2.content, careKit.content)
        XCTAssertEqual(parse2.title, careKit.title)
        XCTAssertEqual(parse2.author, careKit.author)
        
        //Objectable
        XCTAssertEqual(parse2.uuid, careKit.uuid)
        XCTAssertNotNil(parse2.createdDate)
        XCTAssertNotNil(parse2.updatedDate)
        XCTAssertEqual(parse2.timezone, careKit.timezone)
        XCTAssertEqual(parse2.userInfo, careKit.userInfo)
        XCTAssertEqual(parse2.remoteID, careKit.remoteID)
        XCTAssertEqual(parse2.source, careKit.source)
        XCTAssertEqual(parse2.asset, careKit.asset)
        XCTAssertEqual(parse2.schemaVersion, careKit.schemaVersion)
        XCTAssertEqual(parse2.groupIdentifier, careKit.groupIdentifier)
        XCTAssertEqual(parse2.tags, careKit.tags)
        XCTAssertEqual(parse2.notes?.count, 1)
        XCTAssertEqual(parse2.notes?.first?.author, "myId")
        XCTAssertEqual(parse2.notes?.first?.title, "hello")
        XCTAssertEqual(parse2.notes?.first?.content, "world")
    }

    func testPatient() throws {
        var careKit = OCKPatient(id: "myId", givenName: "hello", familyName: "world")
        let careKitNote = OCKNote(author: "myId", title: "hello", content: "world")
        //Special
        careKit.birthday = Date().addingTimeInterval(-300)
        careKit.allergies = ["sneezing"]
        careKit.sex = .female

        //Objectable
        careKit.uuid = UUID()
        careKit.createdDate = Date().addingTimeInterval(-200)
        careKit.deletedDate = Date().addingTimeInterval(-100)
        careKit.updatedDate = Date().addingTimeInterval(-99)
        careKit.timezone = .current
        careKit.userInfo = ["String": "String"]
        careKit.remoteID = "we"
        careKit.groupIdentifier = "mine"
        careKit.tags = ["one", "two"]
        careKit.schemaVersion = .init(majorVersion: 4)
        careKit.source = "yo"
        careKit.asset = "pic"
        careKit.notes = [careKitNote]
        
        //Versionable
        careKit.previousVersionUUID = UUID()
        careKit.nextVersionUUID = UUID()
        careKit.effectiveDate = Date().addingTimeInterval(-199)
        
        //Test CareKit -> Parse
        let parse = try Patient.copyCareKit(careKit)

        //Special
        XCTAssertEqual(parse.name, careKit.name)
        XCTAssertEqual(parse.sex, careKit.sex)
        XCTAssertNotNil(parse.birthday)
        XCTAssertEqual(parse.allergies, careKit.allergies)
        
        //Objectable
        XCTAssertEqual(parse.className, "Patient")
        XCTAssertEqual(parse.entityId, careKit.id)
        XCTAssertEqual(parse.uuid, careKit.uuid)
        XCTAssertNotNil(parse.createdDate)
        XCTAssertNotNil(parse.updatedDate)
        XCTAssertNotNil(parse.deletedDate)
        XCTAssertEqual(parse.timezone, careKit.timezone)
        XCTAssertEqual(parse.userInfo, careKit.userInfo)
        XCTAssertEqual(parse.remoteID, careKit.remoteID)
        XCTAssertEqual(parse.source, careKit.source)
        XCTAssertEqual(parse.asset, careKit.asset)
        XCTAssertEqual(parse.schemaVersion, careKit.schemaVersion)
        XCTAssertEqual(parse.groupIdentifier, careKit.groupIdentifier)
        XCTAssertEqual(parse.tags, careKit.tags)
        XCTAssertEqual(parse.notes?.count, 1)
        XCTAssertEqual(parse.notes?.first?.author, "myId")
        XCTAssertEqual(parse.notes?.first?.title, "hello")
        XCTAssertEqual(parse.notes?.first?.content, "world")
        
        //Versionable
        XCTAssertNotNil(parse.effectiveDate)
        XCTAssertEqual(parse.previousVersionUUID, careKit.previousVersionUUID)
        XCTAssertEqual(parse.nextVersionUUID, careKit.nextVersionUUID)
        
        //Test Parse -> CareKit
        let parse2 = try parse.convertToCareKit()

        //Special
        XCTAssertEqual(parse2.name, careKit.name)
        XCTAssertEqual(parse2.sex, careKit.sex)
        XCTAssertNotNil(parse2.birthday)
        XCTAssertEqual(parse2.allergies, careKit.allergies)
        
        //Objectable
        XCTAssertEqual(parse2.id, careKit.id)
        XCTAssertEqual(parse2.uuid, careKit.uuid)
        XCTAssertNotNil(parse2.createdDate)
        XCTAssertNotNil(parse2.updatedDate)
        XCTAssertNotNil(parse2.deletedDate)
        XCTAssertEqual(parse2.timezone, careKit.timezone)
        XCTAssertEqual(parse2.userInfo, careKit.userInfo)
        XCTAssertEqual(parse2.remoteID, careKit.remoteID)
        XCTAssertEqual(parse2.source, careKit.source)
        XCTAssertEqual(parse2.asset, careKit.asset)
        XCTAssertEqual(parse2.schemaVersion, careKit.schemaVersion)
        XCTAssertEqual(parse2.groupIdentifier, careKit.groupIdentifier)
        XCTAssertEqual(parse2.tags, careKit.tags)
        XCTAssertEqual(parse2.notes?.count, 1)
        XCTAssertEqual(parse2.notes?.first?.author, "myId")
        XCTAssertEqual(parse2.notes?.first?.title, "hello")
        XCTAssertEqual(parse2.notes?.first?.content, "world")
        
        //Versionable
        XCTAssertNotNil(parse2.effectiveDate)
        XCTAssertEqual(parse2.previousVersionUUID, careKit.previousVersionUUID)
        XCTAssertEqual(parse2.nextVersionUUID, careKit.nextVersionUUID)
    }

    func testOutcomeValue() throws {
        var careKit = OCKOutcomeValue(10)
        let careKitNote = OCKNote(author: "myId", title: "hello", content: "world")
        //Special
        careKit.index = 0
        //careKit.kind = "whale"
        careKit.units = "m/s"
        
        //Objectable
        careKit.uuid = UUID()
        careKit.createdDate = Date().addingTimeInterval(-200)
        careKit.updatedDate = Date().addingTimeInterval(-99)
        careKit.timezone = .current
        careKit.userInfo = ["String": "String"]
        careKit.remoteID = "we"
        careKit.groupIdentifier = "mine"
        careKit.tags = ["one", "two"]
        careKit.schemaVersion = .init(majorVersion: 4)
        careKit.source = "yo"
        careKit.asset = "pic"
        careKit.notes = [careKitNote]
        
        //Test CareKit -> Parse
        let parse = try OutcomeValue.copyCareKit(careKit)

        //Special
        XCTAssertEqual(parse.index, careKit.index)
        XCTAssertEqual(parse.kind, careKit.kind)
        XCTAssertEqual(parse.units, careKit.units)
        if let value = parse.value as? Int,
            let careKitValue = careKit.value as? Int {
            XCTAssertEqual(value, careKitValue)
        } else {
            XCTFail("Should have casted")
        }
        
        //Objectable
        XCTAssertEqual(parse.className, "OutcomeValue")
        XCTAssertEqual(parse.uuid, careKit.uuid)
        XCTAssertNotNil(parse.createdDate)
        XCTAssertNotNil(parse.updatedDate)
        XCTAssertEqual(parse.timezone, careKit.timezone)
        XCTAssertEqual(parse.userInfo, careKit.userInfo)
        XCTAssertEqual(parse.remoteID, careKit.remoteID)
        XCTAssertEqual(parse.source, careKit.source)
        XCTAssertEqual(parse.schemaVersion, careKit.schemaVersion)
        XCTAssertEqual(parse.tags, careKit.tags)
        XCTAssertEqual(parse.groupIdentifier, careKit.groupIdentifier)
        XCTAssertEqual(parse.asset, careKit.asset)
        XCTAssertEqual(parse.notes?.count, 1)
        XCTAssertEqual(parse.notes?.first?.author, "myId")
        XCTAssertEqual(parse.notes?.first?.title, "hello")
        XCTAssertEqual(parse.notes?.first?.content, "world")
        
        //Test Parse -> CareKit
        let parse2 = try parse.convertToCareKit()
        //Special
        XCTAssertEqual(parse2.index, careKit.index)
        XCTAssertEqual(parse2.kind, careKit.kind)
        XCTAssertEqual(parse2.units, careKit.units)
        if let value2 = parse2.value as? Int,
            let careKitValue = careKit.value as? Int {
            XCTAssertEqual(value2, careKitValue)
        } else {
            XCTFail("Should have casted")
        }
        
        //Objectable
        XCTAssertEqual(parse2.uuid, careKit.uuid)
        XCTAssertNotNil(parse2.createdDate)
        XCTAssertNotNil(parse2.updatedDate)
        XCTAssertEqual(parse2.timezone, careKit.timezone)
        XCTAssertEqual(parse2.userInfo, careKit.userInfo)
        XCTAssertEqual(parse2.remoteID, careKit.remoteID)
        XCTAssertEqual(parse2.source, careKit.source)
        XCTAssertEqual(parse2.schemaVersion, careKit.schemaVersion)
        XCTAssertEqual(parse2.tags, careKit.tags)
        XCTAssertEqual(parse2.groupIdentifier, careKit.groupIdentifier)
        XCTAssertEqual(parse2.notes?.count, 1)
        XCTAssertEqual(parse2.notes?.first?.author, "myId")
        XCTAssertEqual(parse2.notes?.first?.title, "hello")
        XCTAssertEqual(parse2.notes?.first?.content, "world")
        
        //Test Parse -> ParseServer
        let encoded = try parse.getEncoder().encode(parse)
        let decoded = try parse.getDecoder().decode([String: AnyCodable].self, from: encoded)
        if let decodedValue = decoded["value"]?.value as? [String: Int] {
            XCTAssertEqual(decodedValue["integer"], 10)
        } else {
            XCTFail("Should have decoded as a dictionary and had the necessary value")
        }
        
        //Test Parse -> ParseServer
        let parse3 = try parse.getDecoder().decode(OutcomeValue.self, from: encoded)
        //Special
        XCTAssertEqual(parse2.index, parse3.index)
        XCTAssertEqual(parse2.kind, parse3.kind)
        XCTAssertEqual(parse2.units, parse3.units)
        if let value2 = parse2.value as? Int,
            let parse3Value = parse3.value as? Int {
            XCTAssertEqual(value2, parse3Value)
        } else {
            XCTFail("Should have casted")
        }
        
        //Objectable
        XCTAssertEqual(parse2.uuid, parse3.uuid)
        XCTAssertEqual(parse2.createdDate, parse3.createdDate)
        XCTAssertEqual(parse2.updatedDate, parse3.updatedDate)
        XCTAssertEqual(parse2.timezone, parse3.timezone)
        XCTAssertEqual(parse2.userInfo, parse3.userInfo)
        XCTAssertEqual(parse2.remoteID, parse3.remoteID)
        XCTAssertEqual(parse2.source, parse3.source)
        XCTAssertEqual(parse2.schemaVersion, parse3.schemaVersion)
        XCTAssertEqual(parse2.tags, parse3.tags)
        XCTAssertEqual(parse2.groupIdentifier, parse3.groupIdentifier)
        XCTAssertEqual(parse3.notes?.count, 1)
        XCTAssertEqual(parse3.notes?.first?.author, "myId")
        XCTAssertEqual(parse3.notes?.first?.title, "hello")
        XCTAssertEqual(parse3.notes?.first?.content, "world")
    }

    func testOutcome() throws {
        var careKit = OCKOutcome(taskUUID: UUID(), taskOccurrenceIndex: 0, values: [.init(10)])
        let careKitNote = OCKNote(author: "myId", title: "hello", content: "world")
        
        //Objectable
        careKit.uuid = UUID()
        careKit.createdDate = Date().addingTimeInterval(-200)
        careKit.updatedDate = Date().addingTimeInterval(-99)
        careKit.deletedDate = Date().addingTimeInterval(-1)
        careKit.schemaVersion = .init(majorVersion: 4)
        careKit.remoteID = "we"
        careKit.groupIdentifier = "mine"
        careKit.tags = ["one", "two"]
        careKit.source = "yo"
        careKit.userInfo = ["String": "String"]
        careKit.asset = "pic"
        careKit.notes = [careKitNote]
        careKit.timezone = .current
        
    
        //Test CareKit -> Parse
        let parse = try Outcome.copyCareKit(careKit)

        //Special
        XCTAssertEqual(parse.taskUUID, careKit.taskUUID)
        XCTAssertEqual(parse.taskOccurrenceIndex, careKit.taskOccurrenceIndex)
        XCTAssertEqual(parse.values?.count, 1)
        XCTAssertEqual(careKit.values.count, 1)
        guard let value = parse.values?.first?.value as? Int,
              let careKitValue = careKit.values.first?.value as? Int else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(value, careKitValue)
        
        //Objectable
        XCTAssertEqual(parse.className, "Outcome")
        XCTAssertEqual(parse.uuid, careKit.uuid)
        XCTAssertEqual(parse.entityId, careKit.id)
        XCTAssertNotNil(parse.createdDate)
        XCTAssertNotNil(parse.updatedDate)
        XCTAssertEqual(parse.timezone, careKit.timezone)
        XCTAssertEqual(parse.userInfo, careKit.userInfo)
        XCTAssertEqual(parse.remoteID, careKit.remoteID)
        XCTAssertEqual(parse.source, careKit.source)
        XCTAssertEqual(parse.schemaVersion, careKit.schemaVersion)
        XCTAssertEqual(parse.tags, careKit.tags)
        XCTAssertEqual(parse.groupIdentifier, careKit.groupIdentifier)
        XCTAssertEqual(parse.asset, careKit.asset)
        XCTAssertEqual(parse.notes?.count, 1)
        XCTAssertEqual(parse.notes?.first?.author, "myId")
        XCTAssertEqual(parse.notes?.first?.title, "hello")
        XCTAssertEqual(parse.notes?.first?.content, "world")
        
        //Test Parse -> CareKit
        let parse2 = try parse.convertToCareKit()
        
        //Special
        XCTAssertEqual(parse2.taskUUID, careKit.taskUUID)
        XCTAssertEqual(parse2.taskOccurrenceIndex, careKit.taskOccurrenceIndex)
        XCTAssertEqual(parse2.values.count, 1)
        if let value2 = parse2.values.first?.value as? Int,
            let careKitValue = careKit.values.first?.value as? Int {
            XCTAssertEqual(value2, careKitValue)
        } else {
            XCTFail("Should have casted")
        }
        
        //Objectable
        XCTAssertEqual(parse2.uuid, careKit.uuid)
        XCTAssertNotNil(parse2.createdDate)
        XCTAssertNotNil(parse2.updatedDate)
        XCTAssertEqual(parse2.timezone, careKit.timezone)
        XCTAssertEqual(parse2.userInfo, careKit.userInfo)
        XCTAssertEqual(parse2.remoteID, careKit.remoteID)
        XCTAssertEqual(parse2.source, careKit.source)
        XCTAssertEqual(parse2.schemaVersion, careKit.schemaVersion)
        XCTAssertEqual(parse2.tags, careKit.tags)
        XCTAssertEqual(parse2.groupIdentifier, careKit.groupIdentifier)
        XCTAssertEqual(parse2.asset, careKit.asset)
        XCTAssertEqual(parse2.notes?.count, 1)
        XCTAssertEqual(parse2.notes?.first?.author, "myId")
        XCTAssertEqual(parse2.notes?.first?.title, "hello")
        XCTAssertEqual(parse2.notes?.first?.content, "world")
    }
/*
    func testScheduleElement() throws {
        var careKit = OCKScheduleElement(start: Date(), end: Date().addingTimeInterval(3000), interval: .init(day: 1))

        //Objectable
        careKit.targetValues = [.init(10)]
        careKit.text = "we"
        careKit.duration = .allDay
        
        do {
            //Test CareKit -> Parse
            let parse = try ScheduleElement.copyCareKit(careKit)

            //Special
            XCTAssertEqual(parse.text, careKit.text)
            XCTAssertEqual(parse.duration, careKit.duration)
            XCTAssertEqual(parse.start, careKit.start)
            XCTAssertEqual(parse.interval, careKit.interval)
            XCTAssertEqual(parse.end, careKit.end)
            XCTAssertEqual(parse.targetValues?.count, 1)
            XCTAssertEqual(parse.targetValues?.count, 1)
            if let value = parse.targetValues?.first?.value?.value as? Int,
                let careKitValue = careKit.targetValues.first?.value as? Int {
                XCTAssertEqual(value, careKitValue)
            } else {
                XCTFail("Should have casted")
            }
            
            //Objectable
            XCTAssertEqual(parse.className, "ScheduleElement")
            
            //Test Parse -> CareKit
            let parse2 = try parse.convertToCareKit()
            
            XCTAssertEqual(parse2.text, careKit.text)
            XCTAssertEqual(parse2.duration, careKit.duration)
            XCTAssertEqual(parse2.start, careKit.start)
            XCTAssertEqual(parse2.interval, careKit.interval)
            XCTAssertEqual(parse2.end, careKit.end)
            XCTAssertEqual(parse2.targetValues.count, 1)
            if let value2 = parse2.targetValues.first?.value as? Int,
               let careKitValue = careKit.targetValues.first?.value as? Int {
                XCTAssertEqual(value2, careKitValue)
            } else {
                XCTFail("Should have casted")
            }
            
        } catch {
            XCTFail(error.localizedDescription)
        }
    }*/

    func testTask() throws {
        let careKitSchedule = OCKScheduleElement(start: Date(), end: Date().addingTimeInterval(3000), interval: .init(day: 1))
        var careKit = OCKTask(id: "myId", title: "hello", carePlanUUID: UUID(), schedule: .init(composing: [careKitSchedule]))
        let careKitNote = OCKNote(author: "myId", title: "hello", content: "world")

        //Special
        careKit.impactsAdherence = true
        careKit.instructions = "sneezing"
        careKit.carePlanUUID = UUID()
        
        //Objectable
        careKit.uuid = UUID()
        careKit.createdDate = Date().addingTimeInterval(-200)
        careKit.deletedDate = Date().addingTimeInterval(-100)
        careKit.updatedDate = Date().addingTimeInterval(-99)
        careKit.timezone = .current
        careKit.userInfo = ["String": "String"]
        careKit.remoteID = "we"
        careKit.groupIdentifier = "mine"
        careKit.tags = ["one", "two"]
        careKit.schemaVersion = .init(majorVersion: 4)
        careKit.source = "yo"
        careKit.asset = "pic"
        careKit.notes = [careKitNote]
        
        //Versionable
        careKit.previousVersionUUID = UUID()
        careKit.nextVersionUUID = UUID()
        careKit.effectiveDate = Date().addingTimeInterval(-199)
        
        //Test CareKit -> Parse
        let parse = try Task.copyCareKit(careKit)

        //Special
        XCTAssertEqual(parse.impactsAdherence, careKit.impactsAdherence)
        XCTAssertEqual(parse.title, careKit.title)
        XCTAssertEqual(parse.carePlanUUID, careKit.carePlanUUID)
        //XCTAssertEqual(parse.allergies, careKit.allergies)
        
        //Objectable
        XCTAssertEqual(parse.className, "Task")
        XCTAssertEqual(parse.entityId, careKit.id)
        XCTAssertEqual(parse.uuid, careKit.uuid)
        XCTAssertNotNil(parse.createdDate)
        XCTAssertNotNil(parse.updatedDate)
        XCTAssertNotNil(parse.deletedDate)
        XCTAssertEqual(parse.timezone, careKit.timezone)
        XCTAssertEqual(parse.userInfo, careKit.userInfo)
        XCTAssertEqual(parse.remoteID, careKit.remoteID)
        XCTAssertEqual(parse.source, careKit.source)
        XCTAssertEqual(parse.asset, careKit.asset)
        XCTAssertEqual(parse.schemaVersion, careKit.schemaVersion)
        XCTAssertEqual(parse.groupIdentifier, careKit.groupIdentifier)
        XCTAssertEqual(parse.tags, careKit.tags)
        XCTAssertEqual(parse.notes?.count, 1)
        XCTAssertEqual(parse.notes?.first?.author, "myId")
        XCTAssertEqual(parse.notes?.first?.title, "hello")
        XCTAssertEqual(parse.notes?.first?.content, "world")
        
        //Versionable
        XCTAssertNotNil(parse.effectiveDate)
        XCTAssertEqual(parse.previousVersionUUID, careKit.previousVersionUUID)
        XCTAssertEqual(parse.nextVersionUUID, careKit.nextVersionUUID)
        
        //Test Parse -> CareKit
        let parse2 = try parse.convertToCareKit()

        //Special
        XCTAssertEqual(parse2.impactsAdherence, careKit.impactsAdherence)
        XCTAssertEqual(parse2.title, careKit.title)
        XCTAssertEqual(parse2.carePlanUUID, careKit.carePlanUUID)
        //XCTAssertEqual(parse2.allergies, careKit.allergies)
        
        //Objectable
        XCTAssertEqual(parse2.id, careKit.id)
        XCTAssertEqual(parse2.uuid, careKit.uuid)
        XCTAssertNotNil(parse2.createdDate)
        XCTAssertNotNil(parse2.updatedDate)
        XCTAssertNotNil(parse2.deletedDate)
        XCTAssertEqual(parse2.timezone, careKit.timezone)
        XCTAssertEqual(parse2.userInfo, careKit.userInfo)
        XCTAssertEqual(parse2.remoteID, careKit.remoteID)
        XCTAssertEqual(parse2.source, careKit.source)
        XCTAssertEqual(parse2.asset, careKit.asset)
        XCTAssertEqual(parse2.schemaVersion, careKit.schemaVersion)
        XCTAssertEqual(parse2.groupIdentifier, careKit.groupIdentifier)
        XCTAssertEqual(parse2.tags, careKit.tags)
        XCTAssertEqual(parse2.notes?.count, 1)
        XCTAssertEqual(parse2.notes?.first?.author, "myId")
        XCTAssertEqual(parse2.notes?.first?.title, "hello")
        XCTAssertEqual(parse2.notes?.first?.content, "world")
        
        //Versionable
        XCTAssertNotNil(parse2.effectiveDate)
        XCTAssertEqual(parse2.previousVersionUUID, careKit.previousVersionUUID)
        XCTAssertEqual(parse2.nextVersionUUID, careKit.nextVersionUUID)
    }

    func testCarePlan() throws {
        var careKit = OCKCarePlan(id: "myId", title: "hello", patientUUID: UUID())
        let careKitNote = OCKNote(author: "myId", title: "hello", content: "world")

        //Objectable
        careKit.uuid = UUID()
        careKit.createdDate = Date().addingTimeInterval(-200)
        careKit.deletedDate = Date().addingTimeInterval(-100)
        careKit.updatedDate = Date().addingTimeInterval(-99)
        careKit.timezone = .current
        careKit.userInfo = ["String": "String"]
        careKit.remoteID = "we"
        careKit.groupIdentifier = "mine"
        careKit.tags = ["one", "two"]
        careKit.schemaVersion = .init(majorVersion: 4)
        careKit.source = "yo"
        careKit.asset = "pic"
        careKit.notes = [careKitNote]
        
        //Versionable
        careKit.previousVersionUUID = UUID()
        careKit.nextVersionUUID = UUID()
        careKit.effectiveDate = Date().addingTimeInterval(-199)
        
        //Test CareKit -> Parse
        let parse = try CarePlan.copyCareKit(careKit)

        //Special
        XCTAssertEqual(parse.title, careKit.title)
        XCTAssertEqual(parse.patientUUID, careKit.patientUUID)
        
        //Objectable
        XCTAssertEqual(parse.className, "CarePlan")
        XCTAssertEqual(parse.entityId, careKit.id)
        XCTAssertEqual(parse.uuid, careKit.uuid)
        XCTAssertNotNil(parse.createdDate)
        XCTAssertNotNil(parse.updatedDate)
        XCTAssertNotNil(parse.deletedDate)
        XCTAssertEqual(parse.timezone, careKit.timezone)
        XCTAssertEqual(parse.userInfo, careKit.userInfo)
        XCTAssertEqual(parse.remoteID, careKit.remoteID)
        XCTAssertEqual(parse.source, careKit.source)
        XCTAssertEqual(parse.asset, careKit.asset)
        XCTAssertEqual(parse.schemaVersion, careKit.schemaVersion)
        XCTAssertEqual(parse.groupIdentifier, careKit.groupIdentifier)
        XCTAssertEqual(parse.tags, careKit.tags)
        XCTAssertEqual(parse.notes?.count, 1)
        XCTAssertEqual(parse.notes?.first?.author, "myId")
        XCTAssertEqual(parse.notes?.first?.title, "hello")
        XCTAssertEqual(parse.notes?.first?.content, "world")
        
        //Versionable
        XCTAssertNotNil(parse.effectiveDate)
        XCTAssertEqual(parse.previousVersionUUID, careKit.previousVersionUUID)
        XCTAssertEqual(parse.nextVersionUUID, careKit.nextVersionUUID)
        
        //Test Parse -> CareKit
        let parse2 = try parse.convertToCareKit()

        //Special
        XCTAssertEqual(parse2.title, careKit.title)
        XCTAssertEqual(parse2.patientUUID, careKit.patientUUID)
        //XCTAssertEqual(parse2.allergies, careKit.allergies)
        
        //Objectable
        XCTAssertEqual(parse2.id, careKit.id)
        XCTAssertEqual(parse2.uuid, careKit.uuid)
        XCTAssertNotNil(parse2.createdDate)
        XCTAssertNotNil(parse2.updatedDate)
        XCTAssertNotNil(parse2.deletedDate)
        XCTAssertEqual(parse2.timezone, careKit.timezone)
        XCTAssertEqual(parse2.userInfo, careKit.userInfo)
        XCTAssertEqual(parse2.remoteID, careKit.remoteID)
        XCTAssertEqual(parse2.source, careKit.source)
        XCTAssertEqual(parse2.asset, careKit.asset)
        XCTAssertEqual(parse2.schemaVersion, careKit.schemaVersion)
        XCTAssertEqual(parse2.groupIdentifier, careKit.groupIdentifier)
        XCTAssertEqual(parse2.tags, careKit.tags)
        XCTAssertEqual(parse2.notes?.count, 1)
        XCTAssertEqual(parse2.notes?.first?.author, "myId")
        XCTAssertEqual(parse2.notes?.first?.title, "hello")
        XCTAssertEqual(parse2.notes?.first?.content, "world")
        
        //Versionable
        XCTAssertNotNil(parse2.effectiveDate)
        XCTAssertEqual(parse2.previousVersionUUID, careKit.previousVersionUUID)
        XCTAssertEqual(parse2.nextVersionUUID, careKit.nextVersionUUID)
    }

    func testContact() throws {
        var careKit = OCKContact(id: "myId", givenName: "hello", familyName: "world", carePlanUUID: UUID())
        let careKitNote = OCKNote(author: "myId", title: "hello", content: "world")

        //Special
        let address = OCKPostalAddress()
        address.state = "KY"
        careKit.address = address
        careKit.category = .careProvider
        careKit.organization = "yo"
        careKit.role = "nope"
        careKit.title = "wep"
        careKit.messagingNumbers = [.init(label: "home", value: "555-4325")]
        careKit.emailAddresses = [.init(label: "mine", value: "netrecon@uky.edu")]
        careKit.phoneNumbers = [.init(label: "wer", value: "232-45")]
        careKit.otherContactInfo = [.init(label: "qp", value: "rest")]

        //Objectable
        careKit.uuid = UUID()
        careKit.createdDate = Date().addingTimeInterval(-200)
        careKit.deletedDate = Date().addingTimeInterval(-100)
        careKit.updatedDate = Date().addingTimeInterval(-99)
        careKit.timezone = .current
        careKit.userInfo = ["String": "String"]
        careKit.remoteID = "we"
        careKit.groupIdentifier = "mine"
        careKit.tags = ["one", "two"]
        careKit.schemaVersion = .init(majorVersion: 4)
        careKit.source = "yo"
        careKit.asset = "pic"
        careKit.notes = [careKitNote]
        
        //Versionable
        careKit.previousVersionUUID = UUID()
        careKit.nextVersionUUID = UUID()
        careKit.effectiveDate = Date().addingTimeInterval(-199)
        
        //Test CareKit -> Parse
        let parse = try Contact.copyCareKit(careKit)

        //Special
        XCTAssertEqual(parse.title, careKit.title)
        XCTAssertEqual(parse.carePlanUUID, careKit.carePlanUUID)
        XCTAssertEqual(parse.address, careKit.address)
        XCTAssertEqual(parse.category, careKit.category)
        XCTAssertEqual(parse.role, careKit.role)
        XCTAssertEqual(parse.messagingNumbers, careKit.messagingNumbers)
        XCTAssertEqual(parse.emailAddresses, careKit.emailAddresses)
        XCTAssertEqual(parse.phoneNumbers, careKit.phoneNumbers)
        XCTAssertEqual(parse.otherContactInfo, careKit.otherContactInfo)
        
        //Objectable
        XCTAssertEqual(parse.className, "Contact")
        XCTAssertEqual(parse.entityId, careKit.id)
        XCTAssertEqual(parse.uuid, careKit.uuid)
        XCTAssertNotNil(parse.createdDate)
        XCTAssertNotNil(parse.updatedDate)
        XCTAssertNotNil(parse.deletedDate)
        XCTAssertEqual(parse.timezone, careKit.timezone)
        XCTAssertEqual(parse.userInfo, careKit.userInfo)
        XCTAssertEqual(parse.remoteID, careKit.remoteID)
        XCTAssertEqual(parse.source, careKit.source)
        XCTAssertEqual(parse.asset, careKit.asset)
        XCTAssertEqual(parse.schemaVersion, careKit.schemaVersion)
        XCTAssertEqual(parse.groupIdentifier, careKit.groupIdentifier)
        XCTAssertEqual(parse.tags, careKit.tags)
        XCTAssertEqual(parse.notes?.count, 1)
        XCTAssertEqual(parse.notes?.first?.author, "myId")
        XCTAssertEqual(parse.notes?.first?.title, "hello")
        XCTAssertEqual(parse.notes?.first?.content, "world")
        
        //Versionable
        XCTAssertNotNil(parse.effectiveDate)
        XCTAssertEqual(parse.previousVersionUUID, careKit.previousVersionUUID)
        XCTAssertEqual(parse.nextVersionUUID, careKit.nextVersionUUID)
        
        //Test Parse -> CareKit
        let parse2 = try parse.convertToCareKit()

        //Special
        XCTAssertEqual(parse2.title, careKit.title)
        XCTAssertEqual(parse2.carePlanUUID, careKit.carePlanUUID)
        XCTAssertEqual(parse2.address, careKit.address)
        XCTAssertEqual(parse2.category, careKit.category)
        XCTAssertEqual(parse2.role, careKit.role)
        XCTAssertEqual(parse2.messagingNumbers, careKit.messagingNumbers)
        XCTAssertEqual(parse2.emailAddresses, careKit.emailAddresses)
        XCTAssertEqual(parse2.phoneNumbers, careKit.phoneNumbers)
        XCTAssertEqual(parse2.otherContactInfo, careKit.otherContactInfo)
        
        //Objectable
        XCTAssertEqual(parse2.id, careKit.id)
        XCTAssertEqual(parse2.uuid, careKit.uuid)
        XCTAssertNotNil(parse2.createdDate)
        XCTAssertNotNil(parse2.updatedDate)
        XCTAssertNotNil(parse2.deletedDate)
        XCTAssertEqual(parse2.timezone, careKit.timezone)
        XCTAssertEqual(parse2.userInfo, careKit.userInfo)
        XCTAssertEqual(parse2.remoteID, careKit.remoteID)
        XCTAssertEqual(parse2.source, careKit.source)
        XCTAssertEqual(parse2.asset, careKit.asset)
        XCTAssertEqual(parse2.schemaVersion, careKit.schemaVersion)
        XCTAssertEqual(parse2.groupIdentifier, careKit.groupIdentifier)
        XCTAssertEqual(parse2.tags, careKit.tags)
        XCTAssertEqual(parse2.notes?.count, 1)
        XCTAssertEqual(parse2.notes?.first?.author, "myId")
        XCTAssertEqual(parse2.notes?.first?.title, "hello")
        XCTAssertEqual(parse2.notes?.first?.content, "world")
        
        //Versionable
        XCTAssertNotNil(parse2.effectiveDate)
        XCTAssertEqual(parse2.previousVersionUUID, careKit.previousVersionUUID)
        XCTAssertEqual(parse2.nextVersionUUID, careKit.nextVersionUUID)
    }
/*
    func testAddContact() throws {
        let contact = OCKContact(id: "test", givenName: "hello", familyName: "world", carePlanUUID: nil)
        var savedContact = try store.addContactAndWait(contact)
        //savedContact.title = "me"
        //parse.automaticallySynchronizes = true
        try self.store.updateContactAndWait(savedContact)
        /*
        let revision = store.computeRevision(since: 0)
        XCTAssert(revision.entities.count == 1)
        XCTAssert(revision.entities.first?.entityType == .contact)*/
        let expectation = XCTestExpectation(description: "Synch")
        self.store.synchronize{ error in
            if let error = error {
                XCTFail("\(error.localizedDescription)")
            }
            savedContact.title = "me"
            do {
                let updatedContact = try self.store.updateContactAndWait(savedContact)
                let revision2 = self.store.computeRevision(since: 1)
                XCTAssert(updatedContact.name.familyName == "me")
                XCTAssert(revision2.entities.count == 1)
                XCTAssert(revision2.entities.first?.entityType == .contact)
            } catch {
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 50.0)
    }*/
}

extension ParseCareKitTests: OCKRemoteSynchronizationDelegate, ParseRemoteSynchronizationDelegate{
    func didRequestSynchronization(_ remote: OCKRemoteSynchronizable) {
        print("Implement")
    }
    
    func remote(_ remote: OCKRemoteSynchronizable, didUpdateProgress progress: Double) {
        print("Implement")
    }
    
    func successfullyPushedDataToCloud(){
        print("Implement")
    }
    
    func chooseConflictResolutionPolicy(_ conflict: OCKMergeConflictDescription, completion: @escaping (OCKMergeConflictResolutionPolicy) -> Void) {
        let conflictPolicy = OCKMergeConflictResolutionPolicy.keepRemote
        completion(conflictPolicy)
    }
    
    func storeUpdatedOutcome(_ outcome: OCKOutcome) {
        store.updateOutcome(outcome, callbackQueue: .global(qos: .background), completion: nil)
    }
    
    func storeUpdatedCarePlan(_ carePlan: OCKCarePlan) {
        store.updateAnyCarePlan(carePlan, callbackQueue: .global(qos: .background), completion: nil)
    }
    
    func storeUpdatedContact(_ contact: OCKContact) {
        store.updateAnyContact(contact, callbackQueue: .global(qos: .background), completion: nil)
    }
    
    func storeUpdatedPatient(_ patient: OCKPatient) {
        store.updateAnyPatient(patient, callbackQueue: .global(qos: .background), completion: nil)
    }
    
    func storeUpdatedTask(_ task: OCKTask) {
        store.updateAnyTask(task, callbackQueue: .global(qos: .background), completion: nil)
    }
    
    
}
