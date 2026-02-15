const express = require('express');
const bodyParser = require('body-parser');
const fs = require('fs').promises;
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const DATA_DIR = process.env.DATA_DIR || '/app/data';
const RECORDS_FILE = path.join(DATA_DIR, 'records.json');
const GIFTBOOKS_FILE = path.join(DATA_DIR, 'giftbooks.json');
const PASSWORD_FILE = path.join(DATA_DIR, 'password.json'); // 添加密码文件

// 中间件
app.use(bodyParser.json());
app.use(express.static('public'));

// 处理 favicon 请求
app.get('/favicon.ico', (req, res) => {
    res.setHeader('Content-Type', 'image/x-icon');
    res.sendFile(path.join(__dirname, 'public', 'favicon.svg'), {
        headers: { 'Content-Type': 'image/svg+xml' }
    }, (err) => {
        if (err) {
            res.status(404).end();
        }
    });
});

app.get('/favicon.svg', (req, res) => {
    res.setHeader('Content-Type', 'image/svg+xml');
    res.sendFile(path.join(__dirname, 'public', 'favicon.svg'));
});

// 确保数据目录存在
async function ensureDataDir() {
    try {
        await fs.access(DATA_DIR);
    } catch {
        await fs.mkdir(DATA_DIR, { recursive: true });
    }
}

// 读取密码
async function readPassword() {
    try {
        const data = await fs.readFile(PASSWORD_FILE, 'utf8');
        return JSON.parse(data).password;
    } catch (err) {
        // 如果密码文件不存在，创建默认密码
        const defaultPassword = 'admin';
        await writePassword(defaultPassword);
        return defaultPassword;
    }
}

// 写入密码
async function writePassword(password) {
    const data = { password: password };
    await fs.writeFile(PASSWORD_FILE, JSON.stringify(data, null, 2));
}

// 读取数据
async function readData(file) {
    try {
        const data = await fs.readFile(file, 'utf8');
        return JSON.parse(data);
    } catch {
        return [];
    }
}

// 写入数据
async function writeData(file, data) {
    await fs.writeFile(file, JSON.stringify(data, null, 2));
}

// API 路由

// 获取密码状态
app.get('/api/password/status', async (req, res) => {
    try {
        const password = await readPassword();
        res.json({ hasPassword: !!password, isFirstTime: password === 'admin' });
    } catch (error) {
        res.status(500).json({ error: '无法获取密码状态' });
    }
});

// 设置/修改密码
app.post('/api/password', async (req, res) => {
    try {
        const { oldPassword, newPassword } = req.body;
        const currentPassword = await readPassword();
        
        // 验证旧密码（如果是修改密码）
        if (oldPassword && currentPassword !== oldPassword) {
            return res.status(401).json({ success: false, message: '旧密码错误' });
        }
        
        // 保存新密码
        await writePassword(newPassword);
        res.json({ success: true, message: '密码设置成功' });
    } catch (error) {
        res.status(500).json({ success: false, message: '密码设置失败' });
    }
});

// 验证密码
app.post('/api/password/verify', async (req, res) => {
    try {
        const { password } = req.body;
        const storedPassword = await readPassword();
        
        if (password === storedPassword) {
            res.json({ success: true, message: '验证成功' });
        } else {
            res.status(401).json({ success: false, message: '密码错误' });
        }
    } catch (error) {
        res.status(500).json({ success: false, message: '验证失败' });
    }
});

// 获取所有记录
app.get('/api/records', async (req, res) => {
    try {
        const records = await readData(RECORDS_FILE);
        res.json(records);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// 保存记录
app.post('/api/records', async (req, res) => {
    try {
        const records = req.body;
        await writeData(RECORDS_FILE, records);
        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// 获取所有礼薄
app.get('/api/giftbooks', async (req, res) => {
    try {
        const giftbooks = await readData(GIFTBOOKS_FILE);
        res.json(giftbooks);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// 保存礼薄
app.post('/api/giftbooks', async (req, res) => {
    try {
        const giftbooks = req.body;
        await writeData(GIFTBOOKS_FILE, giftbooks);
        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// 健康检查
app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
});

// 启动服务器
async function start() {
    await ensureDataDir();
    app.listen(PORT, '0.0.0.0', () => {
        console.log(`礼记系统运行在 http://0.0.0.0:${PORT}`);
        console.log(`数据存储目录: ${DATA_DIR}`);
    });
}

start();
