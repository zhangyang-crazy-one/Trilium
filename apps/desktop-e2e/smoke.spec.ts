import { _electron as electron, ElectronApplication, Page } from "@playwright/test";
import { test, expect } from "@playwright/test";
import path from "path";
import fs from "fs";

const DESKTOP_OUT_DIR = path.join(__dirname, "../../apps/desktop/out");
const TIMEOUT_MS = 30_000;

function findElectronExecutable(): string {
    const platform = process.platform;
    const entries = fs.readdirSync(DESKTOP_OUT_DIR);
    
    for (const entry of entries) {
        const fullPath = path.join(DESKTOP_OUT_DIR, entry);
        if (!fs.statSync(fullPath).isDirectory()) continue;

        if (platform === "darwin") {
            const appPath = path.join(fullPath, "TriliumNotes.app/Contents/MacOS/TriliumNotes");
            if (fs.existsSync(appPath)) return appPath;
        } else if (platform === "win32") {
            const exePath = path.join(fullPath, "trilium.exe");
            if (fs.existsSync(exePath)) return exePath;
        } else {
            const linuxPath = path.join(fullPath, "trilium");
            if (fs.existsSync(linuxPath)) return linuxPath;
        }
    }
    
    throw new Error(`No Electron executable found in ${DESKTOP_OUT_DIR}`);
}

test.describe("Desktop Smoke Tests", () => {
    let electronApp: ElectronApplication;
    let mainWindow: Page;

    test.beforeAll(async () => {
        const executablePath = findElectronExecutable();
        console.log(`Launching: ${executablePath}`);

        electronApp = await electron.launch({
            executablePath,
            args: ["--no-sandbox"],
            timeout: TIMEOUT_MS,
            env: {
                ...process.env,
                TRILIUM_DATA_DIR: path.join(__dirname, "test-data"),
                TRILIUM_INTEGRATION_TEST: "memory"
            }
        });

        mainWindow = await electronApp.firstWindow();
        await mainWindow.waitForLoadState("domcontentloaded");
    });

    test.afterAll(async () => {
        if (electronApp) {
            await electronApp.close();
        }
    });

    test("should launch without JavaScript errors", async () => {
        const errors: string[] = [];
        
        mainWindow.on("pageerror", (error) => {
            errors.push(error.message);
        });

        electronApp.on("console", (msg) => {
            if (msg.type() === "error") {
                errors.push(msg.text());
            }
        });

        await mainWindow.waitForTimeout(3000);

        const criticalErrors = errors.filter(e => 
            e.includes("TypeError") || 
            e.includes("ReferenceError") ||
            e.includes("conversion failure") ||
            e.includes("asar")
        );

        expect(criticalErrors).toEqual([]);
    });

    test("should have valid tray (Linux/Windows only)", async () => {
        if (process.platform === "darwin") {
            test.skip();
            return;
        }

        const trayCreatedSuccessfully = await electronApp.evaluate(async () => {
            return (global as unknown as { __trayCreated?: boolean }).__trayCreated !== false;
        });

        expect(trayCreatedSuccessfully).toBe(true);
    });

    test("should load main window content", async () => {
        const title = await mainWindow.title();
        expect(title).toContain("Trilium");
    });

    test("should not have uncaught exceptions in main process", async () => {
        const hasUncaughtException = await electronApp.evaluate(async () => {
            return (global as unknown as { __uncaughtException?: boolean }).__uncaughtException === true;
        });

        expect(hasUncaughtException).toBeFalsy();
    });
});
