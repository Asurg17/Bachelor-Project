package main

import (
	"database/sql"
)

type FileManager struct {
	connectionPool *PGConnectionPool
}

func NewFileManager(connectionPool *PGConnectionPool) *FileManager {
	fileManager := new(FileManager)
	fileManager.connectionPool = connectionPool
	return fileManager
}

// Manager Functions

func (m *FileManager) uploadImage(imageKey string, imageBytes []byte) error {
	var alreadyExists bool

	getQuery := `select true
				from media_files
				where file_key = $1;`

	if err := m.connectionPool.db.QueryRow(getQuery, imageKey).Scan(&alreadyExists); err != nil {
		if err == sql.ErrNoRows {
			alreadyExists = false
		} else {
			return err
		}
	}

	if alreadyExists {
		updateQuery := `update media_files
						set file = $1
						where file_key = $2;`

		_, err := m.connectionPool.db.Exec(updateQuery, imageBytes, imageKey)
		if err != nil {
			return err
		}
	} else {
		insertQuery := `insert into media_files(file_key, file)
						values($1, $2);`

		_, err := m.connectionPool.db.Exec(insertQuery, imageKey, imageBytes)
		if err != nil {
			return err
		}
	}

	return nil
}

func (m *FileManager) uploadAudio(audioKey string, duration string, audioBytes []byte) error {
	insertQuery := `insert into audio_files(audio_key, audio, duration)
					values($1, $2, $3);`

	_, err := m.connectionPool.db.Exec(insertQuery, audioKey, audioBytes, duration)
	if err != nil {
		return err
	}

	return nil
}

func (m *FileManager) getImage(imageKey string) ([]byte, error) {
	var imageBytes []byte

	query := `select file
	        from media_files f
			where f.file_key = $1;`

	if err := m.connectionPool.db.QueryRow(query, imageKey).Scan(&imageBytes); err != nil {
		return nil, err
	}

	return imageBytes, nil
}

func (m *FileManager) getAudio(audioKey string) ([]byte, error) {
	var audioBytes []byte

	query := `select f.audio
	        from audio_files f
			where f.audio_key = $1;`

	if err := m.connectionPool.db.QueryRow(query, audioKey).Scan(&audioBytes); err != nil {
		return nil, err
	}

	return audioBytes, nil
}
