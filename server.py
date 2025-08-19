from flask import Flask, send_from_directory
import os

app = Flask(__name__)

# Flutter 웹 빌드 파일 경로 (절대 경로 사용 권장)
FLUTTER_WEB_BUILD_PATH = os.path.join(os.path.dirname(__file__), 'build/web')

# ===== 1. 모든 정적 파일 서빙 =====
# '/'를 제외한 모든 경로에 대해 정적 파일을 찾아서 반환
@app.route('/<path:path>')
def serve_static_files(path):
    # build/web 디렉토리 내에 요청된 파일이 있는지 확인
    if os.path.exists(os.path.join(FLUTTER_WEB_BUILD_PATH, path)):
        return send_from_directory(FLUTTER_WEB_BUILD_PATH, path)
    else:
        # 파일이 없으면 SPA 라우팅을 위해 index.html 반환
        return serve_index_html()

# ===== 2. SPA 라우팅 (index.html 반환) =====
@app.route('/')
def serve_index_html():
    return send_from_directory(FLUTTER_WEB_BUILD_PATH, 'index.html')

# ===== 3. 개발용 설정 =====
if __name__ == '__main__':
    print(f"Flutter 웹 빌드 경로: {FLUTTER_WEB_BUILD_PATH}")
    print("서버 시작...")
    
    # 서버 실행 설정
    app.run(
        host='0.0.0.0',
        port=51577,
        debug=True  # 개발 시에만 True
    )