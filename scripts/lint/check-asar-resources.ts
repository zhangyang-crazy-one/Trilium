#!/usr/bin/env npx tsx
/**
 * Static analysis to detect potential asar resource access issues.
 * 
 * Detects patterns where file paths are passed directly to Electron APIs
 * that require NativeImage objects when running from asar archives.
 */

import fs from "fs";
import path from "path";
import { glob } from "glob";

interface Issue {
    file: string;
    line: number;
    code: string;
    message: string;
}

const DANGEROUS_PATTERNS = [
    {
        // Menu icon with string path instead of NativeImage
        regex: /icon:\s*(?:getIconPath|path\.join|path\.resolve)\s*\(/g,
        message: "Menu icon should use nativeImage.createFromPath() for asar compatibility",
        contextCheck: (content: string, match: RegExpMatchArray) => {
            // Check if the result is wrapped in nativeImage.createFromPath
            const lineStart = content.lastIndexOf("\n", match.index!) + 1;
            const lineEnd = content.indexOf("\n", match.index!);
            const line = content.slice(lineStart, lineEnd);
            return !line.includes("nativeImage");
        }
    },
    {
        // Tray icon with string path
        regex: /new\s+(?:electron\.)?Tray\s*\(\s*(?:getIconPath|path\.join|path\.resolve)\s*\(/g,
        message: "Tray constructor should use nativeImage for asar compatibility",
        contextCheck: (content: string, match: RegExpMatchArray) => {
            const lineStart = content.lastIndexOf("\n", match.index!) + 1;
            const lineEnd = content.indexOf("\n", match.index!);
            const line = content.slice(lineStart, lineEnd);
            return !line.includes("nativeImage");
        }
    },
    {
        // fs.readFileSync on assets without asar check
        regex: /fs\.readFileSync\s*\(\s*path\.(?:join|resolve)\s*\([^)]*assets[^)]*\)/g,
        message: "Reading assets with fs.readFileSync may fail in asar. Consider using electron.app.getPath or nativeImage",
        contextCheck: () => true
    }
];

async function checkFile(filePath: string): Promise<Issue[]> {
    const issues: Issue[] = [];
    const content = fs.readFileSync(filePath, "utf-8");
    const lines = content.split("\n");

    for (const pattern of DANGEROUS_PATTERNS) {
        let match: RegExpExecArray | null;
        const regex = new RegExp(pattern.regex.source, pattern.regex.flags);
        
        while ((match = regex.exec(content)) !== null) {
            if (pattern.contextCheck(content, match)) {
                const lineNumber = content.slice(0, match.index).split("\n").length;
                issues.push({
                    file: filePath,
                    line: lineNumber,
                    code: lines[lineNumber - 1]?.trim() || "",
                    message: pattern.message
                });
            }
        }
    }

    return issues;
}

async function main() {
    const files = await glob("apps/**/src/**/*.ts", {
        ignore: ["**/node_modules/**", "**/*.spec.ts", "**/*.test.ts"],
        cwd: process.cwd()
    });

    const allIssues: Issue[] = [];

    for (const file of files) {
        const issues = await checkFile(file);
        allIssues.push(...issues);
    }

    if (allIssues.length > 0) {
        console.error("\n❌ Potential asar resource access issues detected:\n");
        
        for (const issue of allIssues) {
            console.error(`  ${issue.file}:${issue.line}`);
            console.error(`    ${issue.code}`);
            console.error(`    ⚠️  ${issue.message}\n`);
        }

        console.error(`\nFound ${allIssues.length} issue(s). Please fix before committing.\n`);
        console.error("Tip: Use electron.nativeImage.createFromPath() for image paths in Menu/Tray APIs.\n");
        process.exit(1);
    }

    console.log("✅ No asar resource access issues detected.");
    process.exit(0);
}

main().catch(console.error);
