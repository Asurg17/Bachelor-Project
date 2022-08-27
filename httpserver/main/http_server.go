package main

import (
	"database/sql"
	"encoding/json"
	"io/ioutil"
	"log"
	"net/http"
)

// SignIn-SignUp structs

type RegisterNewUserParams struct {
	Username    string
	FirstName   string
	LastName    string
	PhoneNumber string
	Password    string
}

type ValidateUserParams struct {
	Username string
	Password string
}

type ChangePasswordParams struct {
	UserId      string
	OldPassword string
	NewPassword string
}

// User structs

type GetUserInfoParams struct {
	UserId string
}

type GetUserGroupsParams struct {
	UserId string
}

type GetUserFriendsParams struct {
	UserId string
}

type GetUserFriendsForGroupParams struct {
	UserId  string
	GroupId string
}

type AddUserToGroupParams struct {
	UserId  string
	GroupId string
}

type LeaveGroupParams struct {
	UserId  string
	GroupId string
}

type ChangePersonalInfoParams struct {
	UserId      string
	Age         string
	PhoneNumber string
	BirthDate   string
}

type UnfriendParams struct {
	UserId   string
	FriendId string
}

// Group structs

type SearchNewGroupsParams struct {
	UserId          string
	GroupIdentifier string
}

type GetGroupMembersParams struct {
	UserId  string
	GroupId string
}

type CreateGroupParams struct {
	UserId           string
	GroupName        string
	GroupDescription string
	MembersCount     string
	IsPrivate        string
}

type SaveGroupUpdatesParams struct {
	UserId           string
	GroupId          string
	GroupName        string
	GroupDescription string
}

type GetGroupMediaFilesParams struct {
	UserId  string
	GroupId string
}

// Notification structs

type GetUserNotificationsParams struct {
	UserId string
}

type SendFriendshipRequestParams struct {
	FromUserId string
	ToUserId   string
}

type AcceptFriendshipRequestParams struct {
	UserId           string
	FromUserId       string
	RequestUniqueKey string
}

type RejectFriendshipRequestParams struct {
	UserId           string
	RequestUniqueKey string
}

type AcceptInvitationParams struct {
	UserId           string
	FromUserId       string
	GroupId          string
	RequestUniqueKey string
}

type RejectInvitationParams struct {
	UserId           string
	RequestUniqueKey string
}

// Message structs

type SendMessageParams struct {
	MessageId         string
	Type              string
	SenderId          string
	GroupId           string
	Content           string
	SendDate          string
	SendDateTimestamp string
	Duration          string
}

type GetAllGroupMessagesParams struct {
	UserId  string
	GroupId string
}

type GetNewMessagesParams struct {
	UserId                       string
	GroupId                      string
	LastMessageSentDateTimestamp string
}

// Additional structs

type GroupMembers struct {
	Members []string
}

//  ################################################################################################################

func isUserValid(userId string, db *sql.DB) bool {
	if userId == "" {
		return false
	}

	getQuery := `select s.user_id
				from users s
				where s.user_id = $1;`

	_, err := db.Exec(getQuery, userId)
	if err != nil {
		return false
	}

	return !(userId == "")
}

//  ################################################################################################################

// SignIn-SignUp

func (s *Server) registerNewUser(w http.ResponseWriter, req *http.Request) {
	var params RegisterNewUserParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	response, err := s.signInUpManager.registerNewUser(params.Username, params.Password, params.FirstName, params.LastName, params.PhoneNumber)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	jsonResp, err := json.Marshal(response)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	w.Write(jsonResp)
}

func (s *Server) validateUser(w http.ResponseWriter, req *http.Request) {
	var params ValidateUserParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	response, err := s.signInUpManager.validateUser(params.Username, params.Password)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	jsonResp, err := json.Marshal(response)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	w.Write(jsonResp)
}

// User

func (s *Server) getUserInfo(w http.ResponseWriter, req *http.Request) {
	var params GetUserInfoParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	response, err := s.userManager.getUserInfo(params.UserId)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	jsonResp, err := json.Marshal(response)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	w.Write(jsonResp)
}

func (s *Server) getUserGroups(w http.ResponseWriter, req *http.Request) {
	var params GetUserGroupsParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	response, err := s.userManager.getUserGroups(params.UserId)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	jsonResp, err := json.Marshal(response)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	w.Write(jsonResp)
}

func (s *Server) getUserFriends(w http.ResponseWriter, req *http.Request) {
	var params GetUserFriendsParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	response, err := s.userManager.getUserFriends(params.UserId)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	jsonResp, err := json.Marshal(response)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	w.Write(jsonResp)
}

func (s *Server) getUserFriendsForGroup(w http.ResponseWriter, req *http.Request) {
	var params GetUserFriendsForGroupParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	response, err := s.userManager.getUserFriendsForGroup(params.UserId, params.GroupId)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	jsonResp, err := json.Marshal(response)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	w.Write(jsonResp)
}

func (s *Server) addUserToGroup(w http.ResponseWriter, req *http.Request) {
	var params AddUserToGroupParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	err = s.userManager.addUserToGroup(params.UserId, params.GroupId)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
}

func (s *Server) leaveGroup(w http.ResponseWriter, req *http.Request) {
	var params LeaveGroupParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	err = s.userManager.leaveGroup(params.UserId, params.GroupId)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
}

func (s *Server) changePassword(w http.ResponseWriter, req *http.Request) {
	var params ChangePasswordParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	err = s.userManager.changePassword(params.UserId, params.OldPassword, params.NewPassword)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
}

func (s *Server) changePersonalInfo(w http.ResponseWriter, req *http.Request) {
	var params ChangePersonalInfoParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	err = s.userManager.changePersonalInfo(params.UserId, params.BirthDate, params.Age, params.PhoneNumber)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
}

func (s *Server) unfriend(w http.ResponseWriter, req *http.Request) {
	var params UnfriendParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	err = s.userManager.unfriend(params.UserId, params.FriendId)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
}

// Group

func (s *Server) searchNewGroups(w http.ResponseWriter, req *http.Request) {
	var params SearchNewGroupsParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	response, err := s.groupManager.searchNewGroups(params.UserId, params.GroupIdentifier)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	jsonResp, err := json.Marshal(response)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	w.Write(jsonResp)
}

func (s *Server) getGroupMembers(w http.ResponseWriter, req *http.Request) {
	var params GetGroupMembersParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	response, err := s.groupManager.getGroupMembers(params.UserId, params.GroupId)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	jsonResp, err := json.Marshal(response)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	w.Write(jsonResp)
}

func (s *Server) createGroup(w http.ResponseWriter, req *http.Request) {
	var params CreateGroupParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	response, err := s.groupManager.createGroup(params.UserId, params.GroupName, params.GroupDescription, params.MembersCount, params.IsPrivate)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	jsonResp, err := json.Marshal(response)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	w.Write(jsonResp)
}

func (s *Server) saveGroupUpdates(w http.ResponseWriter, req *http.Request) {
	var params SaveGroupUpdatesParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	err = s.groupManager.saveGroupUpdates(params.UserId, params.GroupId, params.GroupName, params.GroupDescription)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
}

func (s *Server) getGroupMediaFiles(w http.ResponseWriter, req *http.Request) {
	var params GetGroupMediaFilesParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	response, err := s.groupManager.getGroupMediaFiles(params.UserId, params.GroupId)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	jsonResp, err := json.Marshal(response)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	w.Write(jsonResp)
}

// File

func (s *Server) uploadImage(w http.ResponseWriter, req *http.Request) {
	imageKey := req.URL.Query().Get("imageKey")
	imageBytes, err := ioutil.ReadAll(req.Body)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	err = s.fileManager.uploadImage(imageKey, imageBytes)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
}

func (s *Server) uploadAudio(w http.ResponseWriter, req *http.Request) {
	audioKey := req.URL.Query().Get("audioKey")
	duration := req.URL.Query().Get("duration")
	audioBytes, err := ioutil.ReadAll(req.Body)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	err = s.fileManager.uploadAudio(audioKey, duration, audioBytes)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
}

func (s *Server) getImage(w http.ResponseWriter, req *http.Request) {
	imageKey := req.URL.Query().Get("imageKey")

	response, err := s.fileManager.getImage(imageKey)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	w.Write(response)
}

func (s *Server) getAudio(w http.ResponseWriter, req *http.Request) {
	audioKey := req.URL.Query().Get("audioKey")

	response, err := s.fileManager.getAudio(audioKey)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	w.Write(response)
}

// Notification

func (s *Server) getUserNotifications(w http.ResponseWriter, req *http.Request) {
	var params GetUserNotificationsParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	response, err := s.notificationManager.getUserNotifications(params.UserId)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	jsonResp, err := json.Marshal(response)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
	}
	w.Write(jsonResp)
}

func (s *Server) sendGroupInvitations(w http.ResponseWriter, req *http.Request) {
	userId := req.URL.Query().Get("userId")
	groupId := req.URL.Query().Get("groupId")
	addSelfToGroup := req.URL.Query().Get("addSelfToGroup")

	var groupMembers GroupMembers
	dataBytes, err := ioutil.ReadAll(req.Body)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	err = json.Unmarshal(dataBytes, &groupMembers)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	err = s.notificationManager.sendGroupInvitations(userId, groupId, addSelfToGroup, groupMembers.Members)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
}

func (s *Server) sendFriendshipRequest(w http.ResponseWriter, req *http.Request) {
	var params SendFriendshipRequestParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	err = s.notificationManager.sendFriendshipRequest(params.FromUserId, params.ToUserId)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
}

func (s *Server) acceptFriendshipRequest(w http.ResponseWriter, req *http.Request) {
	var params AcceptFriendshipRequestParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	err = s.notificationManager.acceptFriendshipRequest(params.FromUserId, params.UserId, params.RequestUniqueKey)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
}

func (s *Server) rejectFriendshipRequest(w http.ResponseWriter, req *http.Request) {
	var params RejectFriendshipRequestParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	err = s.notificationManager.rejectFriendshipRequest(params.UserId, params.RequestUniqueKey)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
}

func (s *Server) acceptInvitation(w http.ResponseWriter, req *http.Request) {
	var params AcceptInvitationParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	err = s.notificationManager.acceptInvitation(params.FromUserId, params.UserId, params.GroupId, params.RequestUniqueKey)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
}

func (s *Server) rejectInvitation(w http.ResponseWriter, req *http.Request) {
	var params RejectInvitationParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	err = s.notificationManager.rejectInvitation(params.UserId, params.RequestUniqueKey)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
}

// Message

func (s *Server) sendMessage(w http.ResponseWriter, req *http.Request) {
	var params SendMessageParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	err = s.messageManager.sendMessage(params.MessageId, params.Type, params.SenderId, params.GroupId, params.Content, params.SendDate, params.SendDateTimestamp, params.Duration)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(400)
		return
	}
}

func (s *Server) getAllGroupMessages(w http.ResponseWriter, req *http.Request) {
	var params GetAllGroupMessagesParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	response, err := s.messageManager.getAllGroupMessages(params.UserId, params.GroupId)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	jsonResp, err := json.Marshal(response)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	w.Write(jsonResp)
}

func (s *Server) getNewMessages(w http.ResponseWriter, req *http.Request) {
	var params GetNewMessagesParams

	err := json.NewDecoder(req.Body).Decode(&params)
	if err != nil {
		w.Header().Set("Error", "Bad request")
		w.WriteHeader(400)
		return
	}

	response, err := s.messageManager.getNewMessages(params.UserId, params.GroupId, params.LastMessageSentDateTimestamp)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	jsonResp, err := json.Marshal(response)
	if err != nil {
		w.Header().Set("Error", err.Error())
		w.WriteHeader(500)
		return
	}
	w.Write(jsonResp)
}

type Server struct {
	signInUpManager     *SignInUpManager
	userManager         *UserManager
	groupManager        *GroupManager
	fileManager         *FileManager
	notificationManager *NotificationManager
	messageManager      *MessageManager
}

func NewServer(signInUpManager *SignInUpManager,
	userManager *UserManager,
	groupManager *GroupManager,
	fileManager *FileManager,
	notificationManager *NotificationManager,
	messageManager *MessageManager) *Server {
	return &Server{
		signInUpManager:     signInUpManager,
		userManager:         userManager,
		groupManager:        groupManager,
		fileManager:         fileManager,
		notificationManager: notificationManager,
		messageManager:      messageManager,
	}
}

func (s *Server) Start() {

	// singinupManager
	http.HandleFunc("/registerNewUser", s.registerNewUser)
	http.HandleFunc("/validateUser", s.validateUser)

	// User
	http.HandleFunc("/getUserInfo", s.getUserInfo)
	http.HandleFunc("/getUserGroups", s.getUserGroups)
	http.HandleFunc("/getUserFriends", s.getUserFriends)
	http.HandleFunc("/getUserFriendsForGroup", s.getUserFriendsForGroup)
	http.HandleFunc("/addUserToGroup", s.addUserToGroup)
	http.HandleFunc("/changePassword", s.changePassword)
	http.HandleFunc("/changePersonalInfo", s.changePersonalInfo)
	http.HandleFunc("/unfriend", s.unfriend)

	// Group
	http.HandleFunc("/leaveGroup", s.leaveGroup)
	http.HandleFunc("/createGroup", s.createGroup)
	http.HandleFunc("/getGroupMembers", s.getGroupMembers)
	http.HandleFunc("/getGroupMediaFiles", s.getGroupMediaFiles)
	http.HandleFunc("/saveGroupUpdates", s.saveGroupUpdates)
	http.HandleFunc("/searchNewGroups", s.searchNewGroups)

	// Files
	http.HandleFunc("/getImage", s.getImage)
	http.HandleFunc("/getAudio", s.getAudio)
	http.HandleFunc("/uploadImage", s.uploadImage)
	http.HandleFunc("/uploadAudio", s.uploadAudio)

	// Notifications
	http.HandleFunc("/getUserNotifications", s.getUserNotifications)
	http.HandleFunc("/sendGroupInvitations", s.sendGroupInvitations)
	http.HandleFunc("/sendFriendshipRequest", s.sendFriendshipRequest)
	http.HandleFunc("/acceptFriendshipRequest", s.acceptFriendshipRequest)
	http.HandleFunc("/rejectFriendshipRequest", s.rejectFriendshipRequest)
	http.HandleFunc("/acceptInvitation", s.acceptInvitation)
	http.HandleFunc("/rejectInvitation", s.rejectInvitation)

	// Messages
	http.HandleFunc("/sendMessage", s.sendMessage)
	http.HandleFunc("/getAllGroupMessages", s.getAllGroupMessages)
	http.HandleFunc("/getNewMessages", s.getNewMessages)

	// Listen And Serve
	log.Fatal(http.ListenAndServe(":9000", nil))
}
